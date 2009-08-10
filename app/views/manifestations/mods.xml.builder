xml.instruct! :xml, :version=>"1.0" 
xml.mods('version' => "3.2",
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xmlns' => "http://www.loc.gov/mods/v3"){
  xml.titleInfo{
    xml.title @manifestation.original_title
  }
  @manifestation.authors.collect{|author|
    xml.name('type' => author[:type]){
      xml.namePart author.full_name
    }
  }
  xml.typeOfResource @manifestation.carrier_type.name
  xml.originInfo{
    @manifestation.patrons.each do |patron|
      xml.publisher patron.full_name
    end
    xml.dateIssued @manifestation.date_of_publication
  }
  xml.language{
    xml.languageTerm @manifestation.expressions.first.language.name, 'authority' => 'iso639-2b', 'type' => 'code'
  }
  xml.physicalDescription{
    xml.form @manifestation.carrier_type.name, 'authority' => 'marcform'
  }
  xml.subject{
    @manifestation.subjects.collect{|subject|
      xml.topic subject.term
    }
  }
  xml.classification @manifestation.classification_number, 'authority' => 'ddc'
  xml.recordInfo{
    xml.recordCreationDate @manifestation.created_at
    xml.recordChangeDate @manifestation.updated_at
    xml.recordIdentifier @manifestation.id
  }
}
