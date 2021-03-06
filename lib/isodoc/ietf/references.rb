module IsoDoc::Ietf
  class RfcConvert < ::IsoDoc::Convert
    # TODO displayreference will be implemented as combination of autofetch and user-provided citations

    def bibliography(isoxml, out)
      isoxml.xpath(ns("//references")).each do |f|
        out.references **attr_code(anchor: f["id"]) do |div|
          title = f.at(ns("./title")) and div.name do |name|
            title.children.each { |n| parse(n, name) }
          end
          f.elements.reject do |e|
            %w(reference title bibitem note).include? e.name
          end.each { |e| parse(e, div) }
          biblio_list(f, div, true)
        end
      end
    end

    def biblio_list(f, div, biblio)
      i = 0
      f.xpath(ns("./bibitem | ./note")).each do |b|
        next if implicit_reference(b)
        i += 1 if b.name == "bibitem"
        if b.name == "note" then note_parse(b, div)
        elsif(is_ietf(b)) then ietf_bibitem_entry(div, b, i)
        else
          nonstd_bibitem(div, b, i, biblio)
        end
      end
    end

    def nonstd_bibitem(list, b, ordinal, bibliography)
      uris = b.xpath(ns("./uri"))
      list.reference **attr_code(target: uris.empty? ? nil : uris[0]&.text,
                                 anchor: b["id"]) do |r|
        r.front do |f|
          relaton_to_title(b, f)
          relaton_to_author(b, f)
          relaton_to_date(b, f)
          relaton_to_keyword(b, f)
          relaton_to_abstract(b, f)
        end
        uris[1..-1]&.each do |u|
          r.format nil, **attr_code(target: u.text, type: u["type"])
        end
      end
    end

    def relaton_to_title(b, f)
      id = bibitem_ref_code(b)
      identifier = render_identifier(id)
      title = b&.at(ns("./title")) || b&.at(ns("./formattedref")) or return
      f.title do |t|
        t << "#{identifier}, "
        title.children.each { |n| parse(n, t) }
      end
    end

    def relaton_to_author(b, f)
      auths = b.xpath(ns("./contributor[xmlns:role/@type = 'author' or "\
                 "xmlns:role/@type = 'editor']"))
      auths.empty? and auths = b.xpath(ns("./contributor[xmlns:role/@type = "\
                                          "'publisher']"))
      auths.each do |a|
        role = a.at(ns("./role[@type = 'editor']")) ? "editor" : nil
        p = a&.at(ns("./person/name")) and 
          relaton_person_to_author(p, role, f) or
          relaton_org_to_author(a&.at(ns("./organization")), role, f)
      end
    end

    def relaton_person_to_author(p, role, f)
      fullname = p&.at(ns("./completename"))&.text
      surname = p&.at(ns("./surname"))&.text
      initials = p&.xpath(ns("./initial"))&.map { |i| i.text }&.join(" ") ||
        p&.xpath(ns("./forename"))&.map { |i| i.text[0] }&.join(" ")
      initials = nil if initials.empty?
      f.author nil,
        **attr_code(fullname: fullname, asciiFullname: fullname&.transliterate,
                    role: role, surname: surname, initials: initials,
                    asciiSurname: fullname ? surname&.transliterate : nil,
                    asciiInitials: fullname ? initials&.transliterate : nil)
    end

    def relaton_org_to_author(o, role, f)
      name = o&.at(ns("./name"))&.text
      abbrev = o&.at(ns("./abbreviation"))&.text
      f.author do |a|
        f.organization name, **attr_code(ascii: name&.transliterate, 
                                         abbrev: abbrev)
      end
    end

    def relaton_to_date(b, f)
      date = b.at(ns("./date[@type = 'published']")) ||
        b.at(ns("./date[@type = 'issued']")) ||
        b.at(ns("./date[@type = 'circulated']"))
      return unless date
      attr = date_attr(date&.at(ns("./on | ./from"))&.text) || return
      f.date **attr_code(attr)
    end

    def relaton_to_keyword(b, f)
      b.xpath(ns("./keyword")).each do |k|
        f.keyword do |keyword|
          k.children.each { |n| parse(n, keyword) }
        end
      end
    end

    def relaton_to_abstract(b, f)
      b.xpath(ns("./abstract")).each do |k|
        f.abstract do |abstract|
          k.children.each { |n| parse(n, abstract) }
        end
      end
    end

    def ietf_bibitem_entry(div, b, i)
      url = b&.at(ns("./uri[@type = 'xml']"))&.text
      div << "<xi:include href='#{url}'/>"
    end

    def is_ietf(b)
      url = b.at(ns("./uri[@type = 'xml']")) or return false
      /xml2rfc\.tools\.ietf\.org/.match(url)
    end
  end
end
