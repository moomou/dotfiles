import os
import json
from pathlib import Path

from constant import M_ROOT
from m_base import Base
from util import get_config_yml, update_config_yml, get_gh_token


def compile_context(mk2, context):
    if isinstance(context, list):
        return [compile_context(mk2, item) for item in context]

    elif isinstance(context, dict):
        for k, v in context.items():
            if k.startswith("markdown_"):
                context[k] = mk2.markdown(v)
            else:
                context[k] = compile_context(mk2, v)

    return context


class Www(Base):
    def __init__(self):
        super(Www, self).__init__(["jinja2", "requests", "markdown2"])

    def serve(self):
        import sys

        if not Path(M_ROOT / ".." / "www").exists():
            self.shell("(cd %s/.. && go build" % M_ROOT, stdout=sys.stdout)

        self.shell("%s/../www" % M_ROOT, stdout=sys.stdout)

    def compile_template(self):
        """Find jinja2 template and build by using var in config.yaml"""
        jinja2 = self._module("jinja2")
        markdown2 = self._module("markdown2")

        config = get_config_yml()
        compile_config = config["compile"]

        loader = jinja2.FileSystemLoader(
            "./%s" % compile_config["src_dir"], followlinks=True
        )
        env = jinja2.Environment(loader=loader)

        context = config.get("context", {})
        context = compile_context(markdown2, context)

        for temp_name in env.list_templates(
            filter_func=lambda x: not x.startswith("_")
            and x.endswith(compile_config["ext"])
        ):
            self._logger.info("Compiling %s..." % temp_name)
            temp = env.get_template(temp_name)

            out_dir = compile_config["out_dir"]

            with open("./%s/%s" % (out_dir, temp_name), "wb") as f:
                context["filename"] = os.path.splitext(os.path.basename(temp_name))[0]
                f.write(temp.render(**context).encode("utf-8"))

    def fetch_gh_release(self):
        """
        Fetch last 100 releases and update config.yml
        """
        requests = self._module("requests")
        gh_token = get_gh_token()

        query = """
            {
              repository(name:"ohsloth-release", owner:"ohsloth"){
                releases(last: 100) {
                  edges {
                    node {
                      name
                      url
                      publishedAt
                      description
                    }
                  }
                }
              }
            }
        """

        result = requests.post(
            "https://api.github.com/graphql",
            headers={"Authorization": "bearer %s" % gh_token},
            data=json.dumps({"query": query}),
        )

        data = result.json()

        self._logger.debug(data)
        config = get_config_yml()

        releases = []
        for edge in reversed(data["data"]["repository"]["releases"]["edges"]):
            edge["node"]["markdown_description"] = edge["node"]["description"]
            releases.append(edge["node"])

        config["context"]["releases"] = releases
        update_config_yml(config)

        self._logger.info("updated local config")
