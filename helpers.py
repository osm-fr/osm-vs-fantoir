
def get_code_dept_from_insee(code_insee):
    code_dept = code_insee[0:2]
    if code_dept == '97':
        code_dept = code_insee[0:3]
    return code_dept

def escape_quotes(s):
    return s.replace('\'','\'\'')
