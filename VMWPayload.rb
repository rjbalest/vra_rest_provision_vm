require 'nokogiri'

module VMW

class Payload

  @@basePath
  @@quiet = false
  
  attr_accessor :doc
  
  def initialize(doc, type=:xml)
    if type == :xml
      doc.remove_namespaces!
    end
    @doc = doc
  end

  def self.basePath
    @@basePath
  end
  
  def self.basePath=(path)
    @@basePath = path
  end

  def self.load_xml(filename)
    inf = File.open("%s/%s"%[@@basePath,filename])
    data = inf.read
    self.from_xml(data)
  end

  def self.load_json(filename)
    inf = File.open("%s/%s"%[@@basePath,filename])
    data = inf.read
    self.from_json(data)
  end

  def self.from_xml(data)
    doc = Nokogiri::XML(data)
    payload = Payload.new(doc)
  end

  def self.from_json(data)
    doc = JSON.parse(data)
    payload = Payload.new(doc,:json)
  end

  def save_xml(filename=nil)
    outf = File.open("%s/%s"%[@@basePath,filename], 'w')
    outf.write(doc.to_xml)
    outf.close
    unless @@quiet
      print "\nXML document saved as %s/%s\n" % [VMW::Payload::basePath,filename]
    end
  end

  def save_json(filename=nil)
    outf = File.open("%s/%s"%[@@basePath,filename], 'w')
    outf.write(doc.to_json)
    outf.close
    unless @@quiet
      print "\nJSON document saved as %s/%s\n" % [VMW::Payload::basePath,filename]
    end
  end

  def set_all(path, value)
    set(path, value, true)
  end

  def set(path, value, expectMany=false)
    els = doc.xpath("//%s"%path)
    if els.count > 1 and not expectMany
      # exception
      raise "xpath found %d occurrences of %s but expected it to be unique" % [els.count, path]
    end
    els.each {|el| el.content=value}
  end

  def get(path)
    begin
      els = doc.xpath("//%s"%path)
      el0 = els.first
      unless el0.nil?
        content = el0.content
      else
        content = nil
      end
      content
    rescue Exception => e
      print "Got exception looking for //%s\n" % path
      print "In doc :::::::::::::::::::::::::\n"
      print doc
      print "       :::::::::::::::::::::::::\n"
      
    end
  end

  # Replace the inner xml of named target element with the inner
  # xml of the given source element
  def replaceInner(target_el_name, source_el)
    parent_el = doc.at_css(target_el_name)
    parent_el.children = source_el.children.to_xml
  end

  def appendChildren(parent,element_map,attrs=nil)
    parent_el = doc.at_xpath("//%s" % parent)
    element_map.each do |name,value|
      el = Nokogiri::XML::Node.new name, doc
      el.content = value
      parent_el.add_child(el)
    end
  end
  
  def to_xml
    doc.to_xml
  end

  # print_table: utility to summarize an XML document in tabular form
  #
  # Example:
  # print_table('//Device',['name','ipAddress','status'],'ipAddress')
  #
  # Will print a table of 1 <Device> element per row sorted on <ipAddress>
  # with subelements displayed as columns in the order given.
  #
  def print_table(xpath_expr, tags, sortKey)
    hashes = []
    doc.xpath(xpath_expr).each do |xml|
      hh = {}
      tags.each do |tag|
        hh[tag] = xml.at_xpath(tag).content
      end
      hashes << hh
    end
    print_table_from_array_of_hash(hashes, tags, sortKey)
  end

  def print_table_when_json(tags, sortKey)
    print_table_from_array_of_hash(@doc, tags, sortKey)
  end
  
  def print_table_from_array_of_hash(array_of_hash, tags, sortKey)
    print "\n"
  
    width = {}
    # initialize to width of header fields
    tags.each {|t| width[t]=t.length}

    # expand if data wider than header field
    array_of_hash.each do |dd|
      tags.each do |tag|
        data = dd[tag].to_s # in case numerical data
        width[tag] = data.length if data.length > width[tag]
      end
    end

    #header
    table_width=0
    div = ""
    tags.each do |tag|
      ww = width[tag]
      table_width += ww + 2
      print "  %-#{ww}s" % tag
      div += "  %-#{ww}s" % tag.gsub(/./,"-")
    end
    print "\n%s\n" % div
    #body 
    array_of_hash.sort{|l,r| l[sortKey] <=> r[sortKey]}.each do |hh|
      tags.each do |tag|
        ww = width[tag]
        print "  %-#{ww}s" % hh[tag]
      end
      print "\n"
    end
  end

  
end
end
