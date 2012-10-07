# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require "mechanize"

class AddressValidator

# NEW
# ----------------------------------------------------------
# FIXA ALLA BOX ADRESSER --> DE SKALL INTE ITERERAS MED +2
# TWEEKA ADRESSERNA --> IBLAND SKALL INTE ITERERAS MED +2

  def self.fix_streetnrs
    PostAddr.where("id > 10").limit(100).each do |i|
      @street_nrs = Array.new
      PostAddressNr.select("street_nr").where(:post_addr_id => i.id).each do |j|
        @street_nrs << j.street_nr
      end

      unless @street_nrs.blank?
        i.street_nrs = @street_nrs.to_s
        i.save
      end
      @strett_nrs = nil
    end
  end
  
  
  def self.fix_add()
    PostCode.select("zip").where("id > 14404").limit(7000).each do |zip|
      puts "fetching addresses for: #{zip.zip}" 
      AddressValidator.fetch_address_from_postnr(zip.zip)
      sleep 1
    end
  end

  def self.fetch_address_from_postnr(zip)
    agent = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }

    page = agent.get("http://www.postnummerservice.se/pnrguide/adresser-i-sverige.php")
    
    s_form = page.form("search")
    s_form.field_with(:id => 'e_postalcode').value = zip        
    page2 = agent.submit(s_form, s_form.buttons.first)
    puts "Form submitted"
    error = page2.parser.xpath(".//*[@id='d_results_list']/p").text

    if error == "Inga träffar. Försök igen!"
      return false
    else      
     street = Array.new
     street_nr_from = Array.new
     street_nr_to = Array.new
     zip = Array.new
     city = Array.new
     lkf = Array.new
     county = Array.new
     municipality = Array.new
     

     if error[0..7] == 'Resultat'
       pages = ((error.split('totalt ').last.split(' vid').first.strip.to_i).to_f/20).ceil
     elsif error[0..7] == 'En träff'
       pages = 1
     else
       pages = 0
     end

     $i = 1
     while ($i <= pages)
       puts "1"
       
       url = page2.uri.to_s + "&page=#{$i}"
       sleep 2
       page2 = agent.get(url)
       
       page2.parser.xpath(".//*[@class='r_table']//tr").each do |i|
         i.children.each do |j|
           if j['class'] == 'gata'
             unless j.text == 'Gatuadress' or j.text.blank? 
               street << j.text.strip
             end
           end

           if j['class'] == 'fran'         
             unless j.text == 'Från' or j.text.blank? 
               street_nr_from << j.text.scan(/\d/).join("")
             end
           end

           if j['class'] == 'till'         
             unless j.text == 'Till' or j.text.blank? 
               street_nr_to << j.text.strip
             end
           end

           if j['class'] == 'postnummer'         
             unless j.text == 'Postnr' or j.text.blank? 
               zip << j.text.strip
             end
           end

           if j['class'] == 'postort'         
             unless j.text == 'Postort' or j.text.blank? 
               city << j.text.strip
             end
           end

           if j['class'] == 'lkfkod'                   
             unless j.text == 'LKF-kod' or j.text.blank? 
               lkf << j.text.strip
             end
           end

           if j['class'] == 'namnlan'                   
             unless j.text == 'Län' or j.text.blank? 
               county << j.text.strip
             end
           end

           if j['class'] == 'namnkommun'                   
             unless j.text == 'Kommun' or j.text.blank? 
               municipality << j.text.strip
             end
           end

         end
       end
       
       $i += 1
     end
     puts "iteration done"
     
     $i = 0
     @addresses = Array.new
     while ($i < street.count)
       
       if street[$i] == 'Box'
         $j = street_nr_from[$i].to_i
         @nrs = Array.new 
         while ($j <= street_nr_to[$i].to_i)
           @nrs << $j
           $j += 1
         end
       elsif street.grep(street[$i]).count > 1       
         $j = street_nr_from[$i].to_i
         @nrs = Array.new 
         while ($j <= street_nr_to[$i].to_i)
           @nrs << $j
           $j += 2
         end
       elsif street.grep(street[$i]).count == 1       
         $j = street_nr_from[$i].to_i
         @nrs = Array.new 
         while ($j <= street_nr_to[$i].to_i)
           @nrs << $j
           $j += 1
         end
       end
       
       @addresses << {:street => street[$i], :street_nrs => @nrs, :zip => zip[$i].scan(/\d/).join(''), :city => city[$i], :parish => lkf[$i], :county => county[$i], :municipality => municipality[$i]}
       $i += 1
     end
          
     @addresses.each do |i|       
       streets_on_zip = Array.new
       PostCode.where(:zip => i[:zip]).first.post_addr.each do |j|
         streets_on_zip << j.street
       end
    
       if streets_on_zip.include?(i[:street])
         #KOLLAR OM ALLA NR EXISTERAR
         pa = PostAddr.where(:street => i[:street], :post_code_id => PostCode.where(:zip => i[:zip]).first.id).first
         saved_street_nrs = PostAddressNr.select("street_nr").where(:post_addr_id => pa.id).collect {|p| p.street_nr}
         street_nrs_to_save = i[:street_nrs] - saved_street_nrs

         street_nrs_to_save.each do |j|
             p_a_nr = PostAddressNr.new
             p_a_nr.street_nr = j
             p_a_nr.post_addr_id = pa.id
             p_a_nr.save
             puts "Street NR:#{j} for #{i[:street]} #{i[:zip]} #{i[:city]} was saved to DB"           
         end
         
       else
         post_address = PostAddr.new
         post_address.post_code_id = PostCode.where(:zip => i[:zip]).first.id
         post_address.street = i[:street]
         post_address.save
         
         i[:street_nrs].each do |j|
           p_a_nr = PostAddressNr.new
           p_a_nr.street_nr = j
           p_a_nr.post_addr_id = post_address.id
           p_a_nr.save
         end
         
         puts "#{i[:street]} with Street NRs: #{i[:street_nrs]} on #{i[:zip]} #{i[:city]} was saved to DB"           
       end
     end
     sleep 2
    end       
  end

  def self.something()
    PostAddress.all.each do |i|
      i.post_code_id = PostCode.where(:zip => i.zip).first.id
      i.save
    end
  end

  def self.fetch_property_label_from_address(street, zip)
  end

  def self.fetch_gps_from_address(street, zip, city)
  end
  

#OLD

	def self.perform(household_product_el_id)
		el = HouseholdProductEl.find(household_product_el_id)
		verify(el.address) ? el.address_is_validated : el.address_is_invalidated
	end

	def self.fetch(street, zip, city)    
		encoded_city = URI.encode city.encode("ISO-8859-1")
		encoded_street = URI.encode street.encode("ISO-8859-1")
		url = "http://www.posten.se/soktjanst/postnummersok/resultat.jspv?gatunamn=#{encoded_street}&po=#{encoded_city}"
		doc = Nokogiri::HTML(open(url))
		rows = []
		doc.css("td.firstcol").each do |e|
			md = e.parent.css("td:nth-child(2)").first.content.match /(\d+)([ ]*-[ ]*(\d+)){0,1}/
			if md.nil?
				street_no_span = 0..0
			elsif !md[1].nil? and md[3].nil?
				street_no_span = md[1].to_i..md[1].to_i
			elsif !md[1].nil? and !md[3].nil?
				street_no_span = md[1].to_i..md[3].to_i
			end
			rows << {:street => e.content, 
				:street_no_span => street_no_span, 
				:zip => e.parent.css("td:nth-child(3)").first.content, 
				:city => e.parent.css("td:nth-child(4)").first.content }
		end

		rows		
	end

	def self.verify(address)
		return false if address.nil? or address.street.blank? or address.zip.blank? or address.city.blank?

		street = address.street.gsub(/lgh\.{0,1}[ ]*\d{4}/i, "").gsub(/g\./,"gatan").gsub(/v\./,"vägen")
		zip = address.zip
		city = address.city
		rows = fetch(street, zip, city)
		valid_city = false
		valid_street = false
		valid_street_no = false
		valid_zip = false
		rows.each do |r|
			valid_street = compare(street, r[:street])
			valid_zip = compare(zip, r[:zip])
			valid_city = compare(city, r[:city])
			# :street_no_span is 0..0 if street_no is missing at Posten
			if r[:street_no_span].include?(street[/\d+/].to_i) and not r[:street_no_span] == (0..0) and /\d+/ === street
				valid_street_no = true
			elsif r[:street_no_span] == (0..0) and not /\d+/ === street 
				valid_street_no = true
			end
			if valid_street and valid_street_no and valid_city
				if not valid_zip
					address.zip = r[:zip]
					address.updated_by = "Daemon"
					address.save :validate => false
				end
				break # Everything matches, no action needs to be taken
			end
		end
		if valid_street and valid_city and valid_street_no
			address.set_as_validated
			address.updated_by = "Daemon"
			address.save :validate => false
			return true
		else
			return false
		end
	end
	
	#OLOFS IMPLEMENTATION
	
	def self.validate_onscreen(property_label, street, zip, city)
    if street.blank? and property_label.blank?
      return 'either street or property_label needed'
	  elsif street.blank?
      return 'property_label and zip needed' if property_label.blank? or zip.blank?
	    if verify_zip(zip) == true
        data = validate_property_label(property_label, zip)
        return data
      else
        return 'zipcode does not exist'
      end
    else  	  
	    return 'street, zip and city needed' if street.blank? or zip.blank? or city.blank?
	    #Validate Address
	    if verify_address(street, zip, city) == true	      
	      data = get_property_label(street_cleanup(street), zip, city)
	      return data
      else
        return 'address does not exist on zipcode'
      end
    end		
		
  end
	
	def self.verify_zip(zip)
		return false if zip.blank?
		url = "http://www.posten.se/soktjanst/postnummersok/resultat.jspv?pnr=#{zip}"
		doc = Nokogiri::HTML(open(url))
		rows = []
		count = doc.css("td.firstcol").count 
		if count == 0
		  return false
	  else
	    return true
    end
  end
	
	def self.verify_address(street, zip, city)
		return false if street.nil? or city.blank? or zip.blank?

		street = street_cleanup(street)
		zip = zip
		city = city
		rows = fetch(street, zip, city)		
		valid_city = false
		valid_street = false
		valid_street_no = false
		valid_zip = false
		rows.each do |r|
			valid_zip = compare(zip, r[:zip])
			if valid_zip == true
  		  valid_street = compare(street, r[:street])
  		  if valid_street == true
  		    valid_city = compare(city, r[:city])
  		    if valid_city == true
    			# :street_no_span is 0..0 if street_no is missing at Posten
    			if r[:street_no_span].include?(street[/\d+/].to_i) and not r[:street_no_span] == (0..0) and /\d+/ === street
    				valid_street_no = true
    			elsif r[:street_no_span] == (0..0) and not /\d+/ === street 
    				valid_street_no = true
    			end	
    			
    			if valid_street_no == true
    			  return true
    			end

  			  end
		    end
		  end
		end
		return false

#		return rows
#		return street
#		return valid_street_no
#		return valid_street
#		return valid_zip
#		return valid_city
	end
	
  
  def self.validate_property_label(property_label,zip)

    a = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
		url = "https://app2.trygghansa.se/ZKInsuranceApps/ZKCivilInsuranceUI/Views/SignInsurance/Villa/Init.aspx"
	  page = a.get(url)

		s_form = page.form('form1')
		s_form.field_with(:name => 'TextBoxSocialSecurityNumber').value = '8806048271'
		s_form.radiobuttons_with(:name => 'RadioButtonListTypeOfAddress')[1].check
		s_form.field_with(:name => 'TextBoxAddress').value = property_label
		s_form.field_with(:name => 'TextBoxPostalCode').value = zip
		s_form.field_with(:name => 'TextBoxBuildingYear').value = '1950'

		page2 = a.submit(s_form, s_form.buttons.last)
		message =  page2.parser.xpath(".//*[@id='LabelMessage']").text.strip
		
		if message.blank?
		  return 'property_label exists in ziparea'
	  elsif message == "Vi kan inte hitta fastighetsbeteckningen som du skrivit. Kontrollera stavningen eller fyll i gatuadressen istället"
		  return 'property_label does not exist in ziparea'
	  elsif message == "Vänligen ange ett giltigt postnummer."
	    return 'zipcode does not exist'
    end		
  end

  def self.get_property_label(street,zip,city)
    rows = {}

    a = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
		url = "https://app2.trygghansa.se/ZKInsuranceApps/ZKCivilInsuranceUI/Views/SignInsurance/Villa/Init.aspx"
	  page = a.get(url)

		s_form = page.form('form1')
		s_form.field_with(:name => 'TextBoxSocialSecurityNumber').value = '8806048271'
		s_form.field_with(:name => 'TextBoxAddress').value = street
		s_form.field_with(:name => 'TextBoxPostalCode').value = zip
		s_form.field_with(:name => 'TextBoxBuildingYear').value = '1950'

		page2 = a.submit(s_form, s_form.buttons.last)
		
		message =  page2.parser.xpath(".//*[@id='LabelMessage']").text.strip
		
		if message.blank?
		  rows[:property_label] = page2.parser.xpath(".//*[@id='LabelPropertyDescription']").text.strip
  		rows[:living_area] = page2.parser.xpath(".//*[@id='TextBoxLivingSpace']/@value").text.strip
  		rows[:additional_area] = page2.parser.xpath(".//*[@id='TextBoxAdditionalLivingSpace']/@value").text.strip
	  elsif message == "Vi kan inte hitta fastighetsbeteckningen som du skrivit. Kontrollera stavningen eller fyll i gatuadressen istället"
		  return 'property_label does not exist in ziparea'
	  elsif message == "Vänligen ange ett giltigt postnummer."
	    return 'zipcode does not exist'
    end				
		
		return rows
  end

	## Checks if str1 includes str2
	def self.compare(str1, str2)
		str1 = str1.strip.mb_chars.downcase.to_s
		str2 = str2.strip.mb_chars.downcase.to_s

		return true if str1.include? str2
		return true if str1.gsub(" ","").include? str2.gsub(" ","")

		false
	end
	
	def self.street_cleanup(street)
	  unless street.scan(/LGH/i).blank?
	    street = street.split('LGH').first.strip
    end
	  unless street.scan(/lgh/i).blank?
	    street = street.split('lgh').first.strip
    end
	  unless street.scan(/g\./).blank?
	    street = street.gsub(/g\./,"gatan")
    end
	  unless street.scan(/v\./).blank?
	    street = street.gsub(/v\./,"vägen")
    end    
	  unless street.scan(/g /).blank?
	    street = street.gsub(/g /,"gatan ")
    end
	  unless street.scan(/v /).blank?
	    street = street.gsub(/v /,"vägen ")
    end   
    return street 
  end
	
	
end