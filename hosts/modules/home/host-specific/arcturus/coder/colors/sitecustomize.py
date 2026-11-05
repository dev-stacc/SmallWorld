from rich.style import Style
from rich.themes import DEFAULT

DEFAULT.styles["markdown.code"] = Style(bold=True, color="#@base02@", bgcolor="#@base00@")
DEFAULT.styles["markdown.code_block"] = Style(color="#@base02@", bgcolor="#@base00@")
DEFAULT.styles["markdown.h2"] = Style(color="#@base04@", underline=True)
DEFAULT.styles["markdown.h3"] = Style(color="#@base04@", bold=True)
DEFAULT.styles["markdown.h4"] = Style(color="#@base04@", italic=True)
DEFAULT.styles["markdown.link"] = Style(color="#@base04@")
DEFAULT.styles["markdown.link_url"] = Style(color="#@base04@", underline=True)
