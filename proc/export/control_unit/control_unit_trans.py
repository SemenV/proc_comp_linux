import re
from enum import Enum, auto

class Arrow():

  def __init__(self):
    self.conditions = []

  def find_condition(self,condition):
    for i in self.conditions: 
      if (i == condition):
        return True
    return False


class Node():
    def __init__(self):
      self.children: dict[Arrow,Node] = {}
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


class sec():

  def __init__(self):
    with open('proc\export\control_unit\control_unit_fsm.pu', 'r', encoding='utf-8') as file:
      self.full_content = file.read()
    self.states_arr = []
    self.names_arr  = []
    self.full_content_arr = []
    self.root = None

  def print_s_nodes(self):
    for i in self.states_arr:
      i.print_node()

  def names(self):
    r_array = []
    for i in self.full_content_arr:
      if (i[0] == 'names'):
        self.names_arr.append(i[2])
      else:
        r_array.append(i)
    self.full_content_arr = r_array

  def state(self):
    r_array = []
    for i in self.full_content_arr:
      if (i[0] == 'states'):
        n = Node()
        n.name = i[2]
        self.states_arr.append(n)
        if (n.name == 'S0Fetch'):
          self.root = n

      else:
        r_array.append(i)
    self.full_content_arr = r_array


  def pars(self):
    self.full_content = self.full_content.replace('@startuml ttt','')
    self.full_content = self.full_content.replace('@enduml','')
    self.full_content = self.full_content.replace(' ','')

    self.full_content =  re.split('\n',self.full_content)
    self.full_content = list(filter(lambda x : x != '',self.full_content))


    splitters = '(->|'
    splitters += '-->|'
    splitters += '--->|'
    splitters += ':\[|'
    splitters += '\]|'
    splitters += '\||'
    splitters += '=)'
    res = []
    for i in self.full_content:
      res.append(re.split(splitters,i))
    self.full_content_arr = res


  def find_node_by_name(self,n):
    for i in self.states_arr:
      if (i.name == n):
        return i
      if (n == 'names'):
        continue
    err_msg = 'No such name =' + str(n)
    raise ValueError(err_msg)

  def try_prs(self):
    for line in self.full_content_arr:
      node: Node = self.find_node_by_name(line[0])
      if (line[0] == node.name):
        if (line[1] == '--->'):
          node.repeat = line[2]
        if (line[1] == '-->'):
          node_child = self.find_node_by_name(line[2])
          if (line[3] == ':['):
            arrow = Arrow()
            for cur_condtn in line[4:len(line) - 2]:
              if (cur_condtn != '|'):
                arrow.conditions.append(cur_condtn)
                node.children[arrow] = node_child
          else:
            raise ValueError('Link error')
        if (line[1] == ':['):
          if (line[2] in self.names_arr):
            node.force[line[2]] = line[4]
          else:
            print("error " + str(line))
            raise ValueError('States error')
          


s = sec()
s.pars()
s.names()
s.state()
s.try_prs()

print(s.full_content_arr)
print('names_arr =')
print(s.names_arr)

print('states_arr')
s.print_s_nodes()

print('full_content_arr = ')


control_unit_sv_data = '''module control_unit
(
input IRWrite,
input MemWrite,
input AdrSrc,
input PCWrite,
input op,
input funct3,
input funct7,

output reg RegWrite,
output reg ImmSrc,
output reg ALUSrcA,
output reg ALUSrcB1,
output reg ALUControl,
output reg ResultSrc
);
''' 

#typedef
control_unit_sv_data += 'typedef enum '
control_unit_sv_data += "{ "
for state in s.states_arr:
  control_unit_sv_data += state.name + ',\n'
# , + space
control_unit_sv_data = control_unit_sv_data[0:-2]
control_unit_sv_data += " }"
control_unit_sv_data += " state_ty;\n\n"

#instance
control_unit_sv_data += 'state_ty state, nextstate;\n\n'

#logic for clock
control_unit_sv_data += '''always_ff @(posedge clk, posedge reset)
if (reset) state <= S0Fetch;
else state <= nextstate;\n\n
'''



control_unit_sv_data += '''always_comb begin
nextstate = state;
case (state)\n'''

def recursion_collector(s: Node):
  case_statment = ''
  for arr, nod in s.children.items():
    if (nod.name == 'S0Fetch'):
      return ''
    else:
      case_statment += s.name + ' : case (op)\n'
      for j in arr.conditions:
        if (str(j) == '*' ):
          case_statment += '    ' + ' op ' + ' : ' + 'nextstate = ' + nod.name + ';\n'
        else:
          case_statment += '    ' + str(j) + ' : ' + 'nextstate = ' + nod.name + ';\n'
      
      case_statment += 'endcase\n'

      case_statment += recursion_collector(nod) + '\n'


  
  return case_statment

control_unit_sv_data += recursion_collector(s.root)  + 'endcase\nend\nendmodule\n'


with open('proc\export\control_unit\control_unit.sv', 'w', encoding='utf-8') as file:
  file.write(control_unit_sv_data)

