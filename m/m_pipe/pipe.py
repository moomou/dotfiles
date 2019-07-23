import importlib.util

from m_base import Base


class Pipe(Base):
    def run(self, script="m_process.py"):
        """Provide all the utilities available to in_"""
        if not script.endswith(".py"):
            mod_name = script
            script = "%s.py" % script
        else:
            mod_name = script[:-3]

        spec = importlib.util.spec_from_file_location(mod_name, script)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)

        worker = mod.Worker()
        return worker

    def master(
        self,
        event_script,
        redis_addr="redis://localhost:6379",
        master_chan="pipe_master",
    ):
        """
        Start a pipe master where worker can report errors and master run scripts
        to try to unblock worker
        """
        from m_pipe.pipe_master import PipeMaster

        master = PipeMaster(redis_addr)
        master.start(event_script)

    def ytpipe(self):
        from m_pipe.p_yt import Worker

        return Worker()
