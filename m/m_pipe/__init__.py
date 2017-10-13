from m_base import Base
from m_pipe.pipe import PipeRunner


class Pipe(Base):
    runner = PipeRunner()
