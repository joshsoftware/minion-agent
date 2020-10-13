# This implementation is derived from the incomplete and broken implementation
# in the Crystalline shard found at https://github.com/jtomschroeder/crystalline
#
# This version includes a modification which allows trailing leaves at the
# ends of the tree to be removed. This is an effective way to remove the
# elements which are, generally, the least used.
#
# It also includes a #find method to do a search of the tree without a splay
# operation. This is faster than splaying, but loses the advantage of reorganizing
# around the most often accessed elements.
#
# TODO: Experiment with other variations of splay operations, such as lazy semi-splay
# to see if performance can be improved. Right now this isn't any better than
# just using a Hash and arbitrarily deleting half of the hash if it grows too big.

module Minion
  class SplayTreeMap(K, V)
    def initialize
      @root = nil
      @size = 0
      @header = Node(K, V).new(nil, nil)
    end

    getter size

    def get_root
      @root
    end

    def clear
      @root = nil
      @size = 0
      @header = Node(K, V).new(nil, nil)
    end

    # TODO: This is surprisingly slow. I assume it is due to the overhead
    # of declaring nodes on the heap. Is there a way to make them work as
    # structs instead of classes?
    def push(key, value)
      unless @root
        @root = Node(K, V).new(key, value)
        @size = 1
        return value
      end

      splay(key)

      if root = @root
        cmp = key <=> root.key
        if cmp == 0
          root.value = value
          return value
        end
        node = Node(K, V).new(key, value)
        if cmp == -1
          node.left = root.left
          node.right = root
          root.left = nil
        else
          node.right = root.right
          node.left = root
          root.right = nil
        end
      end

      @root = node
      @size += 1
      value
    end

    def []=(key, value)
      push(key, value)
    end

    def height
      height_recursive(@root)
    end

    def height(key)
      node = @root
      return nil if node.nil?

      h = 0
      loop do
        return nil unless node
        cmp = key <=> node.key
        if cmp == -1
          h += 1
          node = node.left
        elsif cmp == 1
          h += 1
          node = node.right
        else
          return h
        end
      end
    end

    # Recursively determine height
    private def height_recursive(node : Node?)
      if node
        left_height = 1 + height_recursive(node.left)
        right_height = 1 + height_recursive(node.right)

        left_height > right_height ? left_height : right_height
      else
        0
      end
    end

    def has_key?(key)
      !get(key).nil?
    end

    def get(key : K)
      return unless @root

      splay(key)
      if root = @root
        root.key == key ? root.value : nil
      end
    end

    def [](key : K)
      get key
    end

    # Find a key without splaying
    def find(key : K)
      node = @root
      return nil if node.nil?

      loop do
        return nil unless node
        cmp = key <=> node.key
        if cmp == -1
          node = node.left
        elsif cmp == 1
          node = node.right
        else
          return node.value
        end
      end
    end

    def min
      return nil unless @root

      n = @root
      while n && n.left
        n = n.left
      end

      n.not_nil!.key
    end

    def max
      return nil unless @root

      n = @root
      while n && n.right
        n = n.right
      end

      n.not_nil!.key
    end

    def delete(key)
      deleted = nil
      splay(key)
      if root = @root
        if key == root.key # The key exists
          deleted = root.value
          if root.left.nil?
            @root = root.right
          else
            x = root.right
            @root = root.left
            new_root = max
            splay(new_root.not_nil!)
            @root.not_nil!.right = x
          end
          @size -= 1
        end
      end
      deleted
    end

    def each
      to_a
    end

    def to_a
      a = [] of {K, V}
      each {|k, v| a << {k, v}}
      a
    end

    def keys : Array(K)
      a = [] of K
      each {|k| a << k}
      a
    end

    def values : Array(V)
      a = [] of V
      each {|v| a << v}
      a
    end

    # TODO: Make this more like other containers in crystal.
    def each(&blk : K, V ->)
      return if @root.nil?

      each_descend_from(@root, &blk)
    end

    # This will recursively walk the whole tree, calling the given block for each node.
    def each_descend_from(node, &blk : K, V ->)
      return if node.nil?

      each_descend_from(node.left, &blk) if !node.left.nil?
      blk.call(node.key, node.value)
      each_descend_from(node.right, &blk) if !node.right.nil?
    end

    # This will remove all of the leaves at the end of the tree branches.
    # That is, every node that does not have any children. This will tend
    # to remove the least used elements from the tree.
    # This function is expensive, as implemented, as it must walk every
    # node in the tree.
    # TODO: Come up with a more efficient way of getting this same effect.
    def prune
      return if @root.nil?

      height_limit = height / 2

      descend_from(@root.not_nil!, height_limit)
      splay(@root.not_nil!.key)
    end

    def descend_from(node, height_limit, current_height = 0)
      return if node.nil?
      current_height += 1

      n = node.left
      if n && !n.terminal?
        descend_from(n, height_limit, current_height)
      else
        prune_from(node) if current_height > height_limit
      end

      descend_from(node.right, height_limit, current_height) if node.right
    end

    def prune_from(node)
      return if node.nil?
      n = node.left
      if n && n.terminal?
        node.left = nil
        @size -= 1
      end

      n = node.right
      if n && n.terminal?
        node.right = nil
        @size -= 1
      end
    end

    # Moves key to the root, updating the structure in each step.
    private def splay(key : K)
      return nil if key.nil?

      l, r = @header, @header
      t = @root
      @header.left, @header.right = nil, nil

      loop do
        if t
          if (key <=> t.key) == -1
            tl = t.left
            break unless tl
            if (key <=> tl.key) == -1
              y = tl
              t.left = y.right
              y.right = t
              t = y
              break unless t.left
            end
            r.left = t
            r = t
            t = t.left
          elsif (key <=> t.key) == 1
            tr = t.right
            break unless tr
            if (key <=> tr.key) == 1
              y = tr
              t.right = y.left
              y.left = t
              t = y
              break unless t.right
            end
            l.right = t
            l = t
            t = t.right
          else
            break
          end
        else
          break
        end
      end

      if t
        l.right, r.left = t.left, t.right
        t.left, t.right = @header.right, @header.left
        @root = t
      end
    end

    # private
    class Node(K, V)
      property left : Node(K, V)?
      property right : Node(K, V)?

      def initialize(@key : K?, @value : V?, @left = nil, @right = nil)
      end

      def terminal?
        left.nil? && right.nil?
      end

      # Enforce type of node properties (key & value)
      macro node_prop(prop, type)
            def {{prop}}; @{{prop}}.as({{type}}); end
            def {{prop}}=(@{{prop}} : {{type}}); end
          end

      node_prop key, K
      node_prop value, V
    end
  end
end
