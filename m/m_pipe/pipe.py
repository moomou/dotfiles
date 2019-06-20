import importlib.util
import queue

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

    def ytpipe(self):
        from m_pipe.p_yt import Worker

        return Worker()
