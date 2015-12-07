# tree.py
# David Chiang <chiang@isi.edu>

# Copyright (c) 2004-2006 University of Maryland. All rights
# reserved. Do not redistribute without permission from the
# author. Not for commercial use.

import re

class Node:
    "Tree node"
    def __init__(self, label, children):
        self.label = label
        self.children = children
        self.length = 0
        for i in range(len(self.children)):
            self.children[i].parent = self
            self.children[i].order = i
            self.length += self.children[i].length
        if len(self.children) == 0:
            self.length = 1
        self.parent = None
        self.order = 0

    def __str__(self):
        if len(self.children) != 0:
            s = "(" + str(self.label)
            for child in self.children:
                s += " " + child.__str__()
            s += ")"
            return s
        else:
            s = str(self.label)
            s = re.sub("\(", "-LRB-", s)
            s = re.sub("\)", "-RRB-", s)
            return s

    def descendant(self, addr):
        if len(addr) == 0:
            return self
        else:
            return self.children[addr[0]].descendant(addr[1:])

    def insert_child(self, i, child):
        child.parent = self
        self.children[i:i] = [child]
        for j in range(i,len(self.children)):
            self.children[j].order = j
        if len(self.children) > 1:
            self.length += child.length
        else:
            self.length = child.length # because self.label changes into nonterminal

    def delete_child(self, i):
        self.children[i].parent = None
        self.children[i].order = 0
        self.length -= self.children[i].length
        self.children[i:i+1] = []
        for j in range(i,len(self.children)):
            self.children[j].order = j

    def detach(self):
        self.parent.delete_child(self.order)

    def delete_clean(self):
        "Cleans up childless ancestors"
        parent = self.parent
        self.detach()
        if len(parent.children) == 0:
            parent.delete_clean()
        
    def frontier(self):
        if len(self.children) != 0:
            l = []
            for child in self.children:
                l.extend(child.frontier())
            return l
        else:
            return [self]

    def compute_spans(self, i=0):
        self.i = i
        if len(self.children) == 0:
            self.j = i+1
        else:
            for child in self.children:
                child.compute_spans(i=i)
                i = child.j
            self.j = i

    def span_helper(self, i, s):
        # don't include terminals
        if len(self.children) == 0:
            return
        s.setdefault((i,i+self.length), []).append(self.label)
        for child in self.children:
            child.span_helper(i, s)
            i += child.length

    def spans(self):
        """return a hash which maps from spans to lists of labels"""
        s = {}
        self.span_helper(0, s)
        return s

    def bottomup(self):
        for child in self.children:
            for node in child.bottomup():
                yield node
        yield self

def scan_tree(tokens, pos):
    try:
        if tokens[pos] == "(":
            if tokens[pos+1] == "(":
                label = ""
                pos += 1
            else:
                label = tokens[pos+1]
                pos += 2
            children = []
            (child, pos) = scan_tree(tokens, pos)
            while child != None:
                children.append(child)
                (child, pos) = scan_tree(tokens, pos)
            if tokens[pos] == ")":
                return (Node(label, children), pos+1)
            else:
                return (None, pos)
        elif tokens[pos] == ")":
            return (None, pos)
        else:
            label = tokens[pos]
            label = label.replace("-LRB-", "(")
            label = label.replace("-RRB-", ")")
            return (Node(label,[]), pos+1)
    except IndexError:
        return (None, pos)

tokenizer = re.compile(r"\(|\)|[^()\s]+")

def str_to_tree(s):
    (tree, n) = scan_tree(tokenizer.findall(s), 0)
    return tree
