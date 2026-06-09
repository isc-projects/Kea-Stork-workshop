import sys
import re
from pathlib import Path
from markdown2 import Markdown

def decorate(string):
  lines = string.splitlines(True)
  id = 1
  string2 = ''
  for line in lines:

    # replace <p><code> with <pre><code> and </code></p> with </code></pre> should not need  flags=re.MULTILINE
    bid = f"button{id}"
    cbid = f"copybutton{id}"
    replacement = f"<div class=copyCode id={bid}><div class=copyFont id={cbid}><a href=\"javascript:void(0)\" onclick=\"copy2clipboard({id});\"><b><font size=5px>&#x2398;</font></b> COPY</a></div><pre><code id={id}>"
    line = re.sub(r"^<p><code>", replacement, line, flags=re.MULTILINE) # multi-line code block
    line = re.sub(r"^</code></p>",'</code></pre></div>',line, flags=re.MULTILINE) # end of multi-line code block

    # now replace <code> when there is no <pre> in front of it with a classed code
    line = re.sub(r"(?<!pre>)<code>", "<code class=code2>",line) # inline code block
    string2 += line
    id += 1

  head = '<!DOCTYPE HTML><html><head><link rel="stylesheet" href="presentation.css"><script src="copy2clipboard.js"></script></head><body>\n'
  foot = '</body></html>'
  string3 = head + string2 + foot
  return(string3)

# get the arguments (there should be exactly 1)
args = sys.argv[1:]
if len(sys.argv) == 2:
  pass
else:
  print("Reads markdown from provided filename and converts to HTML")
  print("Resulting HTML is printed to stdout")
  print("")
  print("Usage: md2html.py <file>")
  print("")
  sys.exit()

file_path = Path(sys.argv[1])
if file_path.is_file():
  with open(sys.argv[1], "r") as file:
    content = file.read()
    md = Markdown(extras=["strike", "tables"])
    out = md.convert(content)
    out = decorate(out)
    print(out)
else:
  print(f"File {sys.argv[1]} is not a valid file")
  sys.exit()
