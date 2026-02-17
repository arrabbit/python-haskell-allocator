"""
Summary: Handles the logic for 'liveness' analysis and constructs the interference graph.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date:
"""

class InterferenceGraph:
    """
    Interference graph for register allocation.
    Key: Variable name (string)
    Value: Set of interfering variables (set of strings)
    
    Designed with dynamically allocated nodes and edges. 
    *Preferred method to 2D array implementation as there will likely be
    vairables that do not interfere with each other at all, leading to wasted 
    space in a 2D array.
    """
    def __init__(self):
        self.graph = {}
        self.color = {}

    def add_node(self, var):
        if var not in self.graph:
            self.graph[var] = set()

    def add_edge(self, var1, var2):
        """Adds an interference edge between two given variables."""
        if var1 != var2:
            self.add_node(var1)
            self.add_node(var2)
            self.graph[var1].add(var2)
            self.graph[var2].add(var1)

    def __str__(self):
        """ Returns a string representation of interfering vairables in the graph. """
        res = "Interference Graph:\n"
        for node, edges in self.graph.items():
            res += f"  {node}: {', '.join(edges)}\n"
        return res
    
    def is_safe(self, node, register): 
        """Returns a bool checking if any neighbor of node is already assigned to register. """
        for neighbor in self.graph.get(node, set()): 
            if self.color.get(neighbor) == register:
                return False    
        return True
    def allocate_registers(self, num_registers, color_these_nodes): #In rememberance of Mantracker

        #Base Case all nodes colored
        if not color_these_nodes:
            # No more nodes to color
            return True
        
        curr = color_these_nodes[0]
        print(f"Trying to color {curr}")

        for reg in range(num_registers):
            if self.is_safe(curr, reg):
                print(f" Assigning {curr} to reg {reg}")
                self.color[curr] = reg
                if self.allocate_registers(num_registers, color_these_nodes[1:]):
                    # Optimal coloring for all nodes has been found
                    return True
                print(f"Backtracking -> Undoing {curr} from Reg {reg}")
                del self.color[curr]
        # No possible coloring exists
        print(f"Failed to Color")
        return False


    

def build_interfere_graph(instruct_list):
    """
    Builds the interference graph from the given instruction list by
    creating nodes for each live variable and connecting the variables that
    interfere with each other.
    Args:
        instruct_list: An instance of the ThreeAdrInstList containing the list
            of instructions and live variable information.
    Returns:
        graph: An instance of the InterferenceGraph for the given instruction
            list.
    """
    graph = InterferenceGraph()

    # Initialiize set of variables live on exit for given instruction list
    curr_live_vars = set(instruct_list.live_on_exit)

    # Add all live variables to the interference graph as nodes
    for var in curr_live_vars:
        graph.add_node(var)

    # Iterates through each instruction in reverse order to determine variable
    # interference
    reverse_instrct_list = reversed(instruct_list.instructions)
    for instr in reverse_instrct_list:
        
        # Check destination variable
        check_dest_var(instr, graph, curr_live_vars)
        
        # Check source variables
        check_source_var(instr, graph, curr_live_vars)

    return graph


def check_dest_var(instr, graph, curr_live_vars):
    """
    Checks and updates the interference graph for the destination variable
    of the given instruction.
    Args:
        instr: A ThreeAdrInst object representing the instruction to check.
        graph: The interference graph.
        curr_live_vars: The set of currently live variables.
    """
    # Handle destination variables - if the instruction defines a variable,
        # that variable interferes with everything currently live
    if instr.dest:
        graph.add_node(instr.dest)
        for live_var in curr_live_vars:
            graph.add_edge(instr.dest, live_var)
            
        # The defined variable is no longer live before this instruction
        if instr.dest in curr_live_vars:
            curr_live_vars.remove(instr.dest)


def check_source_var(instr, graph, curr_live_vars):
    """
    Checks and updates the interference graph for the source variables
    of the given instruction.
    Args:
        instr: A ThreeAdrInst object representing the instruction to check.
        graph: The interference graph.
        curr_live_vars: The set of currently live variables.
    """   
    # Handle source variables - if the instruction uses a variable, that
    # variable must be live before this instruction
    if instr.src1 and not instr.src1.isdigit(): # Ignore literals
        curr_live_vars.add(instr.src1)
        graph.add_node(instr.src1)

    if instr.src2 and not instr.src2.isdigit(): # Ignore literals
        curr_live_vars.add(instr.src2)
        graph.add_node(instr.src2)