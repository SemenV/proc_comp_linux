import re
from enum import Enum, auto

states_arr = [
    'S0Fetch',
    'S1Decode',
    'S2MemAdr',
    'S3MemRead',
    'S4MemWB',
    'S5MemWrite',
    'S6ExecuteR',
    'S7ALUWB',
    'S8ExecuteL',
    'S9Jal',
    'S10Beq',
]

names_arr  = [
    ['reg '        ,'AdrSrc',        ''],
    ['reg '        ,'IRWrite',       ''],
    ['reg [1:0] '  ,'ALUSrcA',       ''],
    ['reg [1:0] '  ,'ALUSrcB',       ''],
    ['reg [1:0] '  ,'ALUOp',         ''],
    ['reg [1:0] '  ,'ResultSrc',     ''],
    ['reg '        ,'PCUpdate ',     ''],
    ['reg '        ,'Branch',        ''],
    ['reg'         ,'RegWrite',      ''],
    ['reg'         ,'MemWrite',      ''],
    ['reg [2:0]'   ,'ALUControl',    ''],
    ['reg [1:0]'   ,'ImmSrc'         ''],
]


class g_Arrow():
  def __init__(self):
    self.conditions = []

class g_Node():
    def __init__(self):
      self.children: dict[g_Arrow,g_Node] = {}
      self.repeat = 0    
      self.name = ''
      self.signals_vals = {}
      self.force = {}

    def print_node(self):
      print("node_start=======================")
      print('node name = ' + str(self.name))
      print("repeat = ",str(self.repeat))
      ch_str = ""
      for arr, nod in self.children.items():
        for a in arr.conditions:
          ch_str += "cond = " + a + " "
        ch_str += " node = " + nod.name + "|"
      print(ch_str)
      print("node_end=======================")


parallel : set[g_Node] = set() 


def find_node_by_name(parallel,name):
    for node in iter(parallel):
        if (node.name == name):
            return node
        else:
            None


def pars(full_content,parallel : set[g_Node]):
    full_content = full_content.replace(' ','')
    full_content =  re.split('\n',full_content)

    splitters = '(->|'
    splitters += '-->|'
    splitters += '--->|'
    splitters += ':\[|'
    splitters += '\]|'
    splitters += '\||'
    splitters += '=)'
    res = []
    for i in full_content:
        res.append(re.split(splitters,i))

    line_cnt = 0
    for l in res:
        line_cnt += 1
        print('Line number: '+ str(line_cnt))
        print(l)

        if ((l[0] == '@startumlttt') | (l[0] == '@enduml') | (l[0] == '')):
            continue
        else:
            n : g_Node = find_node_by_name(parallel,l[0])
            if (n == None):
                n = g_Node()
                n.name = l[0]
                parallel.add(n)   

            if (l[1] == '-->'):
                arrow = g_Arrow()
                for cond in l[4:-2:2]:
                    arrow.conditions.append(cond)

                end_node = find_node_by_name(parallel,l[2])
                if (end_node == None):
                    end_node = g_Node()
                    end_node.name = l[2]
                    parallel.add(end_node)

                n.children[arrow] = end_node


            elif (l[1] == ':['):
                n.force[l[2]] = l[4]

            elif (l[1] == '--->'):
                n.repeat = l[2]

            else: 
                print('Wrong line')
                print('Line number: '+ str(line_cnt))
                print(l)
                raise Exception()
                   

states_arr = []
names_arr  = []
full_content = ''

with open('proc\export\control_unit\control_unit_fsm.pu', 'r', encoding='utf-8') as file:
    full_content = file.read()
    


pars(full_content,parallel)
root = find_node_by_name(parallel,'S0Fetch')

def prind_g(node: g_Node):            
    node.print_node()
    for arr, nod in node.children.items():
        if (nod.name == 'S0Fetch'):
            return 
        prind_g(nod)

prind_g(root)