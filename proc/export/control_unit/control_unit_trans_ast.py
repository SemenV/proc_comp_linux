import re
from enum import Enum, auto

class Node():
  pass

class Node_Name(Node): #name of the node
  def __init__(self,name):
    super().__init__()
    self.n_name = name

class Number(Node): #all numbers
  def __init__(self,default_val):
    super().__init__()
    self.num = default_val

class Line(Node):
  pass

class Line_Arrow(Line):
  def __init__(self,name_start,name_end):
    super().__init__()
    self.name_start : Node_Name = name_start
    self.name_end : Node_Name = name_end
    self.condition : list[Number] = []

class Signal(Node): 
  def __init__(self,signal_name):
    super().__init__()
    self.signal_name : str = signal_name

class Line_Signal(Line):
  def __init__(self,name,s_name,value):
    super().__init__()
    self.name : Node_Name = None
    self.s_name : Signal = ''
    self.value : Number = 0

class Root_Node(Node):
  def __init__(self):
    super().__init__()
    self.children : set[Line] = set()

class Line_Repeat(Line):
  def __init__(self,name,value):
    super().__init__()
    self.name : Node_Name = None
    self.value : Number = 0

class sec():

  def __init__(self):
    with open('proc\export\control_unit\control_unit_fsm.pu', 'r', encoding='utf-8') as file:
      self.full_content = file.read()
    self.states_arr = [
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
    self.names_arr  = [
        'AdrSrc',
        'IRWrite',
        'ALUSrcA',
        'ALUSrcB',
        'ALUOp',
        'ResultSrc',
        'PCUpdate ',
        'Branch',
        'RegWrite',
        'MemWrite',
    ]

    self.full_content_arr = {}
    self.root : Root_Node = Root_Node()


  def pars(self):

    self.full_content = self.full_content.replace('@startuml ttt','')
    self.full_content = self.full_content.replace('@enduml','')
    self.full_content = self.full_content.replace(' ','')

    self.full_content =  re.split('\n',self.full_content)
    self.full_content = list(filter(lambda x : x != '', self.full_content))


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

    for l in res:
      print(l)
      n : Line = None
      if (l[1] == '-->'):
        n = Line_Arrow(
          name_start = Node_Name(l[0]),
          name_end = Node_Name(l[2]),
        )
        for cond in l[4:-2:2]:
          n.condition.append(Number(cond))

      elif (l[1] == ':['):
        n = Line_Signal(
          name = Node_Name(l[0]),
          s_name = Signal(l[2]),
          value = Number(l[4]),
        )
      elif (l[1] == '--->'):
        n = Line_Repeat(
          name  = Node_Name(l[0]),
          value = Number(l[2]),
        )

      else: 
        print('Wrong action')
        print(l)
        raise Exception()
        
      self.root.children.add(n)

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

parallel : list[g_Node] = []      


def rec(node : Node):
  if isinstance(node,Line_Arrow):
    g_n = g_Node()
    g_n.name = node.name_start
    g_arr = g_Arrow()


  

s = sec()
s.pars()

sss : set[str] = set()
sss.add('1')
print('1' in sss)
print(sss.discard('3'))