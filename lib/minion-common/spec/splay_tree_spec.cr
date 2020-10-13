require "./spec_helper"

describe Minion::SplayTreeMap do
  it "creates a Splay Tree with the specified typing" do
    st = Minion::SplayTreeMap(String, String).new
    st.class.should eq Minion::SplayTreeMap(String, String)
  end

  it "can create trees with complex keys" do
    st = Minion::SplayTreeMap({String, String}, String).new
    10.times {|n| st[{n.to_s, n.to_s}] = n.to_s}

    st.size.should eq 10
    st[{"5","5"}].should eq "5"
  end

  it "inserts 1000 randomly generated unique values and can look them up" do
    ins = {} of Int32 => Int32
    st = Minion::SplayTreeMap(Int32, Int32).new
    1000.times do
      while true
        x = rand(10000000)
        if !ins.has_key?(x)
          ins[x] = x
          st[x] = x
          break
        end
      end
    end

    st.size.should eq 1000

    found = 0
    ins.keys.shuffle.each {|k| found += 1 if st.has_key?(k)}
    found.should eq 1000

    found = 0
    ins.keys.shuffle.each {|k| found += 1 if st[k] == ins[k]}
    found.should eq 1000
  end

  it "can find things without splaying to them" do
    ins = {} of Int32 => Int32
    st = Minion::SplayTreeMap(Int32, Int32).new
    1000.times do
      while true
        x = rand(10000000)
        if !ins.has_key?(x)
          ins[x] = x
          st[x] = x
          break
        end
      end
    end

    found = 0
    ins.keys.shuffle.each {|k| found += 1 if st.find(k) == ins[k]}
    found.should eq 1000
  end

  it "can return the max height of the current tree" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    10.times {|x| st[x] = x}
    st.height.should eq 10
  end

  it "can return the height of a single element in the tree" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    10.times {|x| st[x] = x}
    st.height(5).should eq 4
  end

  it "tends to move the most accessed things to the top of the tree" do
    ins = {} of Int32 => Int32
    st = Minion::SplayTreeMap(Int32, Int32).new
    100000.times do
      while true
        x = rand(10000000)
        if !ins.has_key?(x)
          ins[x] = x
          st[x] = x
          break
        end
      end
    end

    random_300 = ins.keys.shuffle[0..299]
    top_100 = random_300[0..99]
    intermediate_100 = random_300[100..199]
    regular_100 = random_300[200..299]

    1000.times do
      100.times { st[intermediate_100.sample(1).first] }
      1000.times { st[top_100.sample(1).first] }
    end

    top_heights = [] of Int32
    intermediate_heights = [] of Int32
    regular_heights = [] of Int32

    top_100.each {|x| top_heights << st.height(x).not_nil!}
    intermediate_100.each {|x| intermediate_heights << st.height(x).not_nil!}
    regular_100.each {|x| regular_heights << st.height(x).not_nil!}

    sum_top_100 = top_heights.reduce(0) {|a,v| a += v}
    sum_intermediate_100 = intermediate_heights.reduce(0) {|a,v| a += v}
    sum_regular_100 = regular_heights.reduce(0) {|a,v| a += v}

    puts "\naverage height -- top :: intermediate :: other == #{sum_top_100 / 100} :: #{sum_intermediate_100 / 100} :: #{sum_regular_100 / 100}"
    sum_top_100.should be < sum_intermediate_100
    sum_intermediate_100.should be < sum_regular_100
  end

  it "can find the max key" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    10.times {|x| st[x] = x}

    st.max.should eq 9
  end

  it "can find the min key" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    10.times {|x| st[x] = x}

    st.min.should eq 0
  end

  it "can delete an individual element" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    10.times {|x| st[x] = x}
    st.size.should eq 10

    st.delete(5)
    st.size.should eq 9

    st.delete(5)
    st.size.should eq 9
  end

  it "can iterate over the entire tree" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    log = [] of Int32
    10.times {|x| st[x] = x; log << x}

    log.size.should eq 10

    n = 0
    st.each do |x|
      n += 1
      log.delete(x)
    end

    n.should eq 10
    log.size.should eq 0
  end

  it "can return an array of tuples of key and value" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    log = [] of {Int32, Int32}
    10.times {|x| st[x] = x; log << {x, x}}

    a = st.to_a
    a.size.should eq 10

    a.sort.should eq log.sort
  end

  it "can return all of the keys in the tree" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    log = [] of Int32
    10.times {|x| st[x] = x; log << x}

    st.keys.size.should eq 10
    st.keys.sort.should eq log.sort
  end

  it "can return all of the values in the tree" do
    st = Minion::SplayTreeMap(Int32, Int32).new
    log = [] of Int32
    10.times {|x| st[x] = x; log << x}

    st.values.size.should eq 10
    st.values.sort.should eq log.sort
  end

  it "can prune the least used elements from a tree" do
    ins = {} of Int32 => Int32
    st = Minion::SplayTreeMap(Int32, Int32).new
    100000.times do
      while true
        x = rand(10000000)
        if !ins.has_key?(x)
          ins[x] = x
          st[x] = x
          break
        end
      end
    end

    random_300 = ins.keys.shuffle[0..299]
    top_100 = random_300[0..99]
    intermediate_100 = random_300[100..199]
    regular_100 = random_300[200..299]

    1000.times do
      100.times { st[intermediate_100.sample(1).first] }
      1000.times { st[top_100.sample(1).first] }
    end

    st.size.should eq 100000
    st.prune
    st.size.should be < 95000 # It should actually be around 90000, give or take 2000
  end
end
