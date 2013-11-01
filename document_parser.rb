require 'net/http'
require 'pp'
require 'pry'
require 'benchmark'



Pleading = Struct.new(:no, :person, :content, :point)
Point = Struct.new(:no, :title)

class DocumentParsing
  POINT_REGEX = /^(?<no>\d+)\s+\§\s+(?<title>.+?)\s?$/
  PLEADING_REGEX = /^Anf\.\s+(?<no>\d+)\s+(?<person>.+?)(?:\s+replik)?:\s?$/
  attr_reader :points, :pleadings

  def initialize(text)
    @text = text
  end

  def reset
    @points = []
    @pleadings = []
  end

  def current_point
    @points.last
  end

  def current_pleading
    current_pleading = @pleadings.last
    if current_pleading && current_pleading.point == current_point
       current_pleading
    end
  end

  def call
    reset
    @text.lines.each_with_object([]) do |line, points|
      if match_data = line.match(POINT_REGEX)
        point = Point.new(match_data[:no], match_data[:title])
        @points.push(point)
      elsif match_data = line.match(PLEADING_REGEX)
        pleading = Pleading.new(
          match_data[:no],
          match_data[:person],
          "",
          current_point
        )
        @pleadings.push(pleading)
      elsif current_pleading
        current_pleading.content << line
      end
    end
  end
end

host = "data.riksdagen.se"
endpoint = "/dokument/H00911/text"
response = Net::HTTP.get(host, endpoint).force_encoding("UTF-8")

parsing = DocumentParsing.new(response)
parsing.call
puts "--POINTS----------------------------------------"
pp parsing.points
puts "--PLEADINGS-------------------------------------"
pp parsing.pleadings