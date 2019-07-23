import time
from urllib.parse import urlparse

from m_base import Base


class PipeMaster(Base):
    def __init__(self, redis_addr):
        super().__init__(["redis"])
        self.redis_addr = redis_addr

    def start(self, event_script):
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

            event = msg["data"]
            if type(event) is bytes and event.decode("utf-8") in event_script:
                script = event_script[event.decode("utf-8")]
                retcode, _, _ = self.shell(script)

                self._logger.info(
                    "Got {event} and ran {script} with ret {retcode}".format(
                        event=event, script=script, retcode=retcode
                    )
                )
            else:
                self._logger.info("discarded msg:: %s", event)

