import time
from urllib.parse import urlparse

from m_base import Base


class PipeMaster(Base):
    def __init__(self, redis_addr):
        super().__init__(["redis"])
        self.redis_addr = redis_addr

    def parse_msg_data(self, data):
        """
        FIXME: kv not used yet
        """
        if type(data) is not bytes:
            self._logger.info("discarded msg:: %s", data)
            return None, None

        data = data.decode("utf-8")
        event, kv = data.split("~", maxsplit=1)
        event = event.strip()

        if not kv.strip():
            return event, None

        return event, {k: v for k, v in [item.split(":") for item in kv.split(",")]}

    def start(self, event_script):
        """
        event_script: relies on python-fire to parse the incoming json to dictionary
        """
        self._logger.info(
            "Starting pipe master with config:: {config}".format(config=event_script)
        )

        parsed = urlparse(self.redis_addr)
        redis = self._module("redis")
        r = redis.StrictRedis(host=parsed.hostname, port=parsed.port)

        p = r.pubsub()
        p.subscribe("pipe_master")
        while True:
            msg = p.get_message()

            if msg is None:
                time.sleep(0.5)
                continue

            data = msg["data"]
            event, _ = self.parse_msg_data(data)

            if event is None:
                continue

            if event in event_script:
                script = event_script[event]
                retcode, stdout, err = self.shell(script)

                if err:
                    self._logger.error(
                        "event:{event} triggered {script} with ret:{retcode} and err:{err}".format(
                            event=event, script=script, retcode=retcode, err=err
                        )
                    )
                else:
                    self._logger.info(
                        "event:{event} triggered {script} with ret:{retcode} and output:{stdout}".format(
                            event=event, script=script, retcode=retcode, stdout=stdout
                        )
                    )

                r.publish("pipe_worker", stdout.decode("utf-8"))
            else:
                self._logger.info("discarded msg:: %s", event)

