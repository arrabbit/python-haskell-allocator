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
    

def build_interfere_graph(instruct_list):
    """
    Builds the interference graph from the given instruction list by updating
    each variable name to be unique and then iterating through the instruction 
    list in reverse order, creating nodes for each live variable and connecting
    the variables that interfere with each other.
    Args:
        instruct_list: An instance of the ThreeAdrInstList containing the list
            of instructions and live variable information.
    Returns:
        graph: An instance of the InterferenceGraph for the given instruction
            list.
    """
    # Rename variables in the instruction list to ensure uniqueness
    rename_vars(instruct_list)
    
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


def rename_vars(instruct_list):
    """
    Renames variables in the instruction list to ensure that each variable is
    defined only once, which is a requirement for the interference graph
    construction.
    Args:
        instruct_list: An instance of the ThreeAdrInstList containing the list
            of instructions and live variable information.
    """
    
    var_versions = {}
    active_names = {}

    for instr in instruct_list.instructions:
        # Rename source variables
        instr.src1 = process_var(instr.src1, var_versions, active_names)
        instr.src2 = process_var(instr.src2, var_versions, active_names)

        # Rename destination variable
        if instr.dest:
            # Determine new version
            curr_version = var_versions.get(instr.dest, -1)
            new_version = curr_version + 1
            var_versions[instr.dest] = new_version

            # Create new name and update mapping
            new_name = f"{instr.dest}_{new_version}"
            active_names[instr.dest] = new_name
            
            # Update instruction
            instr.dest = new_name

    # Update live on exit variables to their active names
    new_live_on_exit = []
    for var in instruct_list.live_on_exit:
        # Process each variable to get its active name and add to the new list
        renamed_var = process_var(var, var_versions, active_names)
        new_live_on_exit.append(renamed_var)
    
    # Update the instruction list's live on exit with the new renamed variables
    instruct_list.set_live_on_exit(new_live_on_exit)


def process_var(var_name, var_versions, active_names):
    """
    Checks if var_name is a valid variable (not None, not literal).
    Initializes it if live-on-entry, and returns the current active name.

    Args:
        var_name: The name of the variable to process.
        var_versions: A dictionary mapping variable names to their current
            version numbers.
        active_names: A dictionary mapping variable names to their active
            (renamed) names.
    """
    if var_name and not var_name.isdigit(): # Ignore None and literals
        # Check if variable is live on entry if so, initialize it to version 0
        if var_name not in active_names:
            var_versions[var_name] = 0
            active_names[var_name] = f"{var_name}_0"
        # Return the active name for use in instruction updates
        return active_names[var_name]
    
    return var_name # Return original value if None or literal

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