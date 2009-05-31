# добавить метод к классу Стринг
# endl2br
class String
  def endl2br
    self.gsub("\n", "<br />")
  end
  def space2br
    # Любое кол-во пробелов на один
    # удалить пробелы в начале и конце
    str= self.strip
    str.gsub!(/\s+/, " ")
    str.gsub(/\s+/, '<br />')
  end
end

# ---------------------------------------------------------------



=begin
  #def recursive_merge(hash= nil)
  
  a= {
    :basic=>{
      :show=>true,
      :posts=>false,
      :reports=>true,
      :callback=>false,
      :some_special=>false
    }
  }

  b= {
    :basic=>{
      :callback=>true,
      :some_special=>{
        :test_one=>true,
        :test45=>{
          :test_one=>"my test var"
        }
      }
    }
  }
  
  >a.recursive_merge(b)
  
  :basic: 
    :show: true
    :some_special: 
      :test_one: true
      :test45: 
        :test_one: my test var
    :callback: true
    :posts: false
    :reports: true
=end
   
# ---------------------------------------------------------------
