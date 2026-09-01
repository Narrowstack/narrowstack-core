"""Template dlt pipeline — copy and customize in private semantics repo."""

from dlt.common.pipeline import TRefreshMode


def run(source_config: dict | None = None) -> None:
    raise NotImplementedError("Copy _template_pipeline.py to a named pipeline in private repo")
