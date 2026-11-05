from pygments.style import Style
from pygments.token import Keyword, Name, Comment, String, Error, Number, Operator, Generic, Whitespace

class Pygarnment(Style):
    background_color = "#@base00@"
    highlight_color = "#@base01@"

    styles = {
        Whitespace:                "#@base01@",
        Comment:                   "italic #@base05@",
        Comment.Preproc:           "noitalic #@base02@",
        Comment.Special:           "bold italic #@base04@",

        Keyword:                   "bold #@base02@",
        Keyword.Constant:          "#@base02@",
        Keyword.Declaration:       "#@base02@",
        Keyword.Namespace:         "#@base03@",
        Keyword.Pseudo:            "#@base02@",
        Keyword.Reserved:          "#@base02@",
        Keyword.Type:              "#@base03@",

        Operator:                  "#@base02@",
        Operator.Word:             "bold #@base02@",

        Name:                      "#@base02@",
        Name.Attribute:            "#@base03@",
        Name.Builtin:              "#@base04@",
        Name.Builtin.Pseudo:       "#@base04@",
        Name.Class:                "#@base03@",
        Name.Constant:             "#@base02@",
        Name.Decorator:            "#@base04@",
        Name.Entity:               "#@base02@",
        Name.Exception:            "#@base04@",
        Name.Function:             "#@base03@",
        Name.Label:                "#@base02@",
        Name.Namespace:            "#@base03@",
        Name.Other:                "#@base02@",
        Name.Property:             "#@base03@",
        Name.Tag:                  "#@base02@",
        Name.Variable:             "#@base03@",
        Name.Variable.Class:       "#@base03@",
        Name.Variable.Global:      "#@base03@",
        Name.Variable.Instance:    "#@base03@",

        String:                    "#@base05@",
        String.Atom:               "#@base02@",
        String.Backtick:           "#@base05@",
        String.Char:               "#@base05@",
        String.Doc:                "italic #@base05@",
        String.Double:             "#@base05@",
        String.Escape:             "#@base04@",
        String.Heredoc:            "#@base05@",
        String.Interpol:           "#@base04@",
        String.Other:              "#@base05@",
        String.Regex:              "#@base04@",
        String.Single:             "#@base05@",
        String.Symbol:             "#@base02@",

        Number:                    "#@base02@",
        Number.Float:              "#@base02@",
        Number.Hex:                "#@base02@",
        Number.Integer:            "#@base02@",
        Number.Oct:                "#@base02@",

        Error:                     "#@base04@",
        Generic:                   "#@base02@",
        Generic.Deleted:           "#@base04@",
        Generic.Emph:              "italic",
        Generic.Error:             "#@base04@",
        Generic.Heading:           "#@base02@",
        Generic.Inserted:          "#@base03@",
        Generic.Output:            "#@base02@",
        Generic.Prompt:            "#@base04@",
        Generic.Strong:            "bold",
        Generic.Subheading:        "#@base02@",
        Generic.Traceback:         "#@base04@",
    }
