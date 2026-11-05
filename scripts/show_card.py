import re,sys
f=sys.argv[1]
t=open(f,encoding='utf8',newline='').read().replace('\r\n','\n')
for lab in sys.argv[2:]:
    m=re.search(r'qwebr_calc_card\(\s*label = "%s".*?\n\)\n'%re.escape(lab),t,re.S)
    c=re.search(r'```\{webr-r\}\n#\| label: %s\n(.*?)\n```'%re.escape(lab),t,re.S)
    print("#####",lab); print(m.group(0) if m else 'NOCARD'); print(c.group(1) if c else 'NOCELL')
