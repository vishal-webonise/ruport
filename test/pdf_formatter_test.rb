require "test/helpers"

class TestRenderPDFTable < Test::Unit::TestCase

  def test_render_pdf_basic  
    # can't render without column names
    data = [[1,2],[3,4]].to_table
    assert_raise(Ruport::FormatterError) do
      data.to_pdf 
    end      

    data.column_names = %w[a b]
    assert_nothing_raised { data.to_pdf }
    
    assert_nothing_raised { Table(%w[a b c]).to_pdf }
  end     
                              
  # this is mostly to check that the transaction hack gets called
  def test_relatively_large_pdf
     table = Table("test/samples/dates.csv")  
     table.reduce(0..99)
     assert_nothing_raised { table.to_pdf }
  end 
     
  # this is just to make sure that the column_opts code is being called.
  # FIXME: add mocks to be sure
  def test_table_with_options
    data = [[1,2],[3,4]].to_table(%w[a b])
    assert_nothing_raised do
      data.to_pdf(:table_format => { 
            :column_options => { :justification => :center } } ) 
    end
  end
  
  #--------BUG TRAPS--------#
  
  # PDF::SimpleTable does not handle symbols as column names
  # Ruport should smartly fix this surprising behaviour (#283) 
  def test_tables_should_render_with_symbol_column_name
    data = [[1,2,3],[4,5,6]].to_table([:a,:b,:c])
    assert_nothing_raised { data.to_pdf }
  end  
  
end    

class TestRenderPDFGrouping < Test::Unit::TestCase                                  
   
  #--------BUG TRAPS----------#
  
  # As of Ruport 0.10.0, PDF's justified group output was throwing
  # UnknownFormatError  (#288)
  def test_group_styles_should_not_throw_error
     table = [[1,2,3],[4,5,6],[1,7,9]].to_table(%w[a b c]) 
     grouping = Grouping(table,:by => "a")
     assert_nothing_raised { grouping.to_pdf } 
     assert_nothing_raised { grouping.to_pdf(:style => :inline) }
     assert_nothing_raised { grouping.to_pdf(:style => :offset) }     
     assert_nothing_raised { grouping.to_pdf(:style => :justified) }
     assert_nothing_raised { grouping.to_pdf(:style => :separated) }
     assert_raises(NotImplementedError) do 
       grouping.to_pdf(:style => :red_snapper) 
     end       
  end    
  
  def test_grouping_should_have_consistent_font_size
    a = Table(%w[a b c]) <<  %w[eye like chicken] << %w[eye like liver] << 
                               %w[meow mix meow ] << %w[mix please deliver ] 
    b = Grouping(a, :by => "a")
    splat = b.to_pdf.split("\n") 
    splat.grep(/meow/).each do |m|
      assert_equal '10.0', m.split[5] 
    end                  
    splat.grep(/mix/).each do |m|
      assert_equal '10.0', m.split[5] 
    end                          
    splat.grep(/eye/).each do |m|
      assert_equal '10.0', m.split[5]
    end
  end
  
end

class TestPDFFormatterHelpers < Test::Unit::TestCase   
  
  def test_boundaries
     a = Ruport::Formatter::PDF.new
     
     assert_equal 36, a.left_boundary    
     a.pdf_writer.left_margin = 50 
     assert_equal 50, a.left_boundary   
     
     assert_equal 576, a.right_boundary
     a.pdf_writer.right_margin -= 10  
     assert_equal 586, a.right_boundary 
     
     assert_equal 756, a.top_boundary
     a.pdf_writer.top_margin -= 10
     assert_equal 766, a.top_boundary
     
     assert_equal 36, a.bottom_boundary
     a.pdf_writer.bottom_margin -= 10
     assert_equal 26, a.bottom_boundary             
  end
     
  def test_move_cursor
     a = Ruport::Formatter::PDF.new
     a.move_cursor_to(500)
     assert_equal(500,a.cursor)  
     a.move_cursor(-25)
     assert_equal(475,a.cursor)
     a.move_cursor(50)
     assert_equal(525,a.cursor)
  end           
  
  def test_padding
    a = Ruport::Formatter::PDF.new
    a.move_cursor_to(100)             
    
    # padding on top and bottom
    a.pad(10) do        
      assert_equal 90, a.cursor
      a.move_cursor(-10)      
      assert_equal 80, a.cursor
    end
    assert_equal(70,a.cursor)  
    
    a.move_cursor_to(100)
    
    # padding just on top  
    a.pad_top(10) do
      assert_equal 90, a.cursor
      a.move_cursor(-10)
      assert_equal 80, a.cursor
    end
    
    assert_equal 80, a.cursor   
    
    a.move_cursor_to(100)  
    
    # padding just on bottom
    a.pad_bottom(10) do
      assert_equal 100, a.cursor
      a.move_cursor(-10)
      assert_equal 90, a.cursor
    end  
    
    assert_equal 80, a.cursor        
  end
  
  def test_draw_text_retains_cursor
    a = Ruport::Formatter::PDF.new
    a.move_cursor_to(100)
    
    a.draw_text "foo", :left => a.left_boundary
    assert_equal 100, a.cursor
    
    a.draw_text "foo", :left => a.left_boundary + 50, :y => 500
    assert_equal 100, a.cursor
  end
end
