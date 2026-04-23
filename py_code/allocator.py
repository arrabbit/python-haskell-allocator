"""
Summary: Handles the logic for 'liveness' analysis and constructs the interference graph.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: March 27, 2026
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
        """
        Initializes an empty InterferenceGraph with no nodes or
        colour assignments.
        """
        self.graph = {}
        self.color = {}
        
    def add_node(self, var):
        """
        Adds a variable as a node in the interference graph if it
        does not already exist.
        Args:
            var: The variable name (str) to add as a node.
        Returns:
            None
        """
        if var not in self.graph:
            self.graph[var] = set()

    def add_edge(self, var1, var2):
        """
        Adds an undirected interference edge between two variables.
        Creates nodes for either variable if they do not already exist.
        No edge is added if both variables are the same.
        Args:
            var1: The first variable name (str).
            var2: The second variable name (str).
        Returns:
            None
        """
        if var1 != var2:
            self.add_node(var1)
            self.add_node(var2)
            self.graph[var1].add(var2)
            self.graph[var2].add(var1)

    def __str__(self):
        """
        Returns a formatted string representation of the interference
        graph, listing each node and its interfering variables.
        Returns:
            str: The graph formatted with one node per line, showing
                each variable and its comma-separated neighbours.
        """
        res = "Interference Graph:\n"
        for node, edges in self.graph.items():
            res += f"  {node}: {', '.join(edges)}\n"
        return res
    
    def is_safe(self, node, register): 
        """
        Checks whether assigning the given register to the given node
        would conflict with any of its neighbours' current assignments.
        Args:
            node: The variable name (str) to check.
            register: The register number (int) being considered.
        Returns:
            bool: True if no neighbour of the node is already assigned
                to the given register, False otherwise.
        """
        for neighbor in self.graph.get(node, set()): 
            if self.color.get(neighbor) == register:
                return False    
        return True
      
    def allocate_registers(self, num_registers, color_these_nodes):
        """
        Attempts to assign registers to all nodes using recursive
        backtracking graph colouring.
        Args:
            num_registers: The number of available CPU registers
                (colours).
            color_these_nodes: A list of variable name strings still
                to be coloured.
        Returns:
            bool: True if a valid colouring was found for all nodes,
                False otherwise.
        """
        #Base Case all nodes colored
        if not color_these_nodes:
            # No more nodes to color
            return True
        
        curr = color_these_nodes[0]

        for reg in range(num_registers):
            if self.is_safe(curr, reg):
                self.color[curr] = reg
                if self.allocate_registers(num_registers, color_these_nodes[1:]):
                    # Optimal coloring for all nodes has been found
                    return True
                del self.color[curr]
        # No possible coloring exists
        return False
    

def _init_live_vars(instruct_list, graph):
    """Seed the graph with live-on-exit nodes and return the initial live set."""
    live = set(instruct_list.live_on_exit)
    for var in live:
        graph.add_node(var)
    return live


def build_interfere_graph(instruct_list):
    """
    Builds the interference graph from the given instruction list by
    iterating through the instructions in reverse order, creating nodes
    for each live variable and connecting the variables that interfere
    with each other.
    Args:
        instruct_list: An instance of the ThreeAdrInstList containing the list
            of instructions and live variable information.
    Returns:
        graph: An instance of the InterferenceGraph for the given instruction
            list.
    """
    graph = InterferenceGraph()
    curr_live_vars = _init_live_vars(instruct_list, graph)

    for instr in reversed(instruct_list.instructions):
        check_dest_var(instr, graph, curr_live_vars)
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