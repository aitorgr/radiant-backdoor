module BackDoor

  FLAG_ATTRIBUTE = :@backdoor_processed 
  EXPANSION_PREFIX = "="

  def attr
    unless attributes.instance_variable_get FLAG_ATTRIBUTE
      attributes.each do |key,value|
        # *toDO* if we use "locals" instead of "globals" in "globals.page.instance_eval", in <r:children:each> "self" is different from outter scope, why?
        attributes[ key] = globals.page.instance_eval( value[ 1..-1]).to_s if value && value.length > 1 && value[ 0..0] == EXPANSION_PREFIX
      end
      attributes.instance_variable_set FLAG_ATTRIBUTE, true
    end
    attributes
  end

end
