"""Append goal/goal_test/mode='task' to a calculator card. Usage: add_goal(file, label, goal, test)"""
import re,sys
def span(s,i):
    d=0
    for k in range(i,len(s)):
        if s[k]=='(': d+=1
        elif s[k]==')':
            d-=1
            if d==0: return k
def add_goal(f,label,goal,test):
    raw=open(f,'rb').read().decode('utf8'); crlf='\r\n' in raw; t=raw.replace('\r\n','\n')
    k=t.index('label = "%s"'%label); st=t.rfind('qwebr_calc_card(',0,k)+len('qwebr_calc_card'); en=span(t,st)
    card=t[st:en+1]; assert 'goal' not in card,label
    new=card[:-1].rstrip()+',\n  goal = "%s",\n  goal_test = "%s",\n  mode = "task")'%(goal,test)
    t=t[:st]+new+t[en+1:]
    open(f,'wb').write((t.replace('\n','\r\n') if crlf else t).encode('utf8'))
