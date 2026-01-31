"""
Summary: Handles the logic for 'liveness' analysis and constructs the interference graph.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date:
"""

class Interfere_graph:
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
        res = "Interference Graph:\n"
        for node, edges in self.graph.items():
            res += f"  {node}: {', '.join(edges)}\n"
        return res