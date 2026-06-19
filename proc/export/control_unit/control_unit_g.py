import re
from enum import Enum, auto

states_set = {
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
}

names_w_type : dict[str,str] = {}
names_w_type['AdrSrc'] = 'output '
names_w_type['IRWrite'] = 'output '
names_w_type['ALUSrcA'] = 'output  [1:0] '
names_w_type['ALUSrcB'] = 'output  [1:0] '
names_w_type['ALUOp'] = 'output  [1:0] '
names_w_type['ResultSrc'] = 'output  [1:0] '
names_w_type['PCUpdate'] = 'output  '
names_w_type['Branch'] = 'output ' 
names_w_type['RegWrite'] = 'output '
names_w_type['MemWrite'] = 'output '
names_w_type['ALUControl'] = 'output  [2:0] '
names_w_type['ImmSrc'] = 'output  [1:0]'

names_w_type['op'] = 'input [6:0] '
names_w_type['func3'] = 'input [3:0] '
names_w_type['func7_5'] = 'input [0:0] '


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
                   

full_content = ''

with open('proc\export\control_unit\control_unit_fsm.pu', 'r', encoding='utf-8') as file:
    full_content = file.read()
    


pars(full_content,parallel)
# root = find_node_by_name(parallel,'S0Fetch')
print("states_set ==========================================")
print(states_set)

def checker(parallel,states_set,names_w_type):
    states : set[str] = set()
    for i in parallel:
        states.add(i.name)
    
    # diff = (states_set - states) | (states - states_set)
    # if (len(diff) != 0):
    #     print(diff)
    #     raise Exception('Wrong states')

    names_key = names_w_type.keys()
    for j in parallel:
        diff2 = (names_key - j.force) |  (j.force - names_key)
        print('j[name] = ' + str(j.name))

        # if (len(diff2) != 0):
        #     print(diff2)
        #     raise Exception('Wrong force signals')




checker(parallel,states_set,names_w_type)


def new_line(index,length):
    return (',\n' if (index != (length - 1)) else '\n')


def generate(
        in_out,
        states,
        parallel,
        start_node = 'S0Fetch',
        ):
    
    in_out_str = ''
    for index, (name, direction) in enumerate(in_out.items()):
        in_out_str += direction + ' ' + name + new_line(index,len(in_out))

    states_str = ''
    for index, (state) in enumerate(states):
        states_str += state + new_line(index,len(states))

    outer_string = 'case (state)\n'
    for node in parallel:
        outer_string += '    ' + node.name + ' : '


        #inner case
        inner_string = 'case(op)\n'
        for arrow, node_child in node.children.items():

            steps_str = ''
            node_condition = ''
            #conditions inner
            for cond_index , (cond) in enumerate(arrow.conditions):
                if (cond == '*'):
                    node_condition += 'op'
                else:
                    node_condition += cond
            steps_str += '        ' +node_condition + ' : nextstate =' + node_child.name + ';'

            inner_string += steps_str + '\n'


        outer_string +=  inner_string + '    ' + 'endcase\n\n'

    outer_string += 'endcase\n\n'

    return f"""module control_unit
(
{in_out_str}
);
typedef enum reg [31:0] {{ 
{states_str}    
}} states_type;

states_type state, nextstate;

always_ff @(posedge clk, posedge reset)
    if (reset) state <= {start_node};
    else state <= nextstate;

always_comb
begin
{outer_string}
end

endmodule
    """
    

with open('proc\export\control_unit\control_unit.sv', 'w', encoding='utf-8') as file:
  file.write(generate(names_w_type,states_set,parallel))

# def print_g(node: g_Node,states_set,names_w_type):

#     node.print_node()
#     for arr, nod in node.children.items():
#         if (nod.name == 'S0Fetch'):
#             return 
#         print_g(nod,states_set,names_w_type)

#     # if ((node.name == 'S0Fetch') & (len(states_set) == 0)):
#     #     pass
#     # else:
#     #     print('Not all states shown')
#     #     print(states_set)
#     #     raise Exception()


# # print_g(root,states_set,names_w_type)
# print(states_set)