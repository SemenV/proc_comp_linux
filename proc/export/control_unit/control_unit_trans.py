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