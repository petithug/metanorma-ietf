require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Ietf do
  it "removes empty text elements" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == {blank}
    INPUT
       #{BLANK_HDR}
              <sections>
         <clause id="_" inline-header="false" obligation="normative">

       </clause>
       </sections>
       </ietf-standard>
    OUTPUT
  end

  it "processes stem-only terms as admitted" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === stem:[t_90]

      stem:[t_91]

      Time
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_"><preferred><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>90</mn></msub></math></stem></preferred><admitted><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>91</mn></msub></math></stem></admitted>
       <definition><p id="_">Time</p></definition></term>
       </terms>
       </sections>
       </ietf-standard>
    OUTPUT
  end

  it "moves term domains out of the term definition paragraph" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Tempus

      domain:[relativity] Time
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_">
         <preferred>Tempus</preferred>
         <domain>relativity</domain><definition><p id="_"> Time</p></definition>
       </term>
       </terms>
       </sections>
       </ietf-standard>
    OUTPUT
  end

  it "permits multiple blocks in term definition paragraph" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :stem:

      == Terms and Definitions

      === stem:[t_90]

      [stem]
      ++++
      t_A
      ++++

      This paragraph is extraneous
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_"><preferred><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>90</mn></msub></math></stem></preferred><definition><formula id="_"> 
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mi>A</mi></msub></math></stem> 
       </formula>
       <p id="_">This paragraph is extraneous</p></definition>
       </term>
       </terms>
       </sections>
       </ietf-standard>
    OUTPUT
  end

  it "strips any initial boilerplate from terms and definitions" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      I am boilerplate

      * So am I

      === Time

      This paragraph is extraneous
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative"><title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>

       <term id="_">
       <preferred>Time</preferred>
         <definition><p id="_">This paragraph is extraneous</p></definition>
       </term></terms>
       </sections>
       </ietf-standard>
    OUTPUT
  end

  it "converts xrefs to references into erefs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      <<iso216#123,of,text>>
      <<biblio,format=counter:text1>>

      [[biblio]]
      [bibliography]
      == Normative References
      * [[[iso216,ISO 216:2001]]], _Reference_
    INPUT
      #{BLANK_HDR}
        <preface><foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type='inline' displayFormat='of' relative='123' bibitemid='iso216' citeas='ISO 216:2001'>text</eref>
<xref target='biblio' format='counter'>text1</xref>
      </p>
      </foreword></preface><sections>
      </sections><bibliography><references id="biblio" obligation="informative">
        <title>Normative References</title>
        <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216:2001</docidentifier>
         <date type="published">
           <on>2001</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
      </references>
      </bibliography>
      </ietf-standard>
    OUTPUT
  end

  it "extracts localities from erefs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      <<iso216,whole,clause=3,example=9-11,locality:prelude=33,locality:entirety:the reference>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
      #{BLANK_HDR}
      <preface><foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO 216"><locality type="whole"/><locality type="clause"><referenceFrom>3</referenceFrom></locality><locality type="example"><referenceFrom>9</referenceFrom><referenceTo>11</referenceTo></locality><locality type="locality:prelude"><referenceFrom>33</referenceFrom></locality><locality type="locality:entirety"/>the reference</eref>
        </p>
      </foreword></preface><sections>
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216</docidentifier>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
      </references>
      </bibliography>
      </ietf-standard>
    OUTPUT
  end


  it "strips type from xrefs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>

      [bibliography]
      == Clause
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
       #{BLANK_HDR}
       <preface>
       <foreword id="_" obligation="informative">
         <title>Foreword</title>
         <p id="_">
         <eref type="inline" bibitemid="iso216" citeas="ISO 216"/>
       </p>
       </foreword></preface><sections>
       </sections><bibliography><references id="_" obligation="informative">
  <title>Bibliography</title>
  <bibitem id="iso216" type="standard">
  <title format="text/plain">Reference</title>
  <docidentifier>ISO 216</docidentifier>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>ISO</name>
    </organization>
  </contributor>
</bibitem>
</references></bibliography>
       </ietf-standard>
    OUTPUT
  end

  it "processes localities in term sources" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [.source]
      <<ISO2191,section=1>>
      INPUT
              #{BLANK_HDR}
       <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_">
         <preferred>Term1</preferred>
         <termsource status="identical">
         <origin bibitemid="ISO2191" type="inline" citeas=""><locality type="section"><referenceFrom>1</referenceFrom></locality></origin>
       </termsource>
       </term>
       </terms>
       </sections>
       </ietf-standard>
      OUTPUT
  end

  it "removes extraneous material from Normative References" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      This is extraneous information

      * [[[iso216,ISO 216]]], _Reference_
    INPUT
      #{BLANK_HDR}
      <sections></sections>
      <bibliography><references id="_" obligation="informative"><title>Normative References</title>
             <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216</docidentifier>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
      </references>
      </bibliography>
      </ietf-standard>
    OUTPUT
  end

        it "renumbers numeric references in Bibliography sequentially" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      <<iso123>>
      <<iso124>>

      [bibliography]
      == Bibliography

      * [[[iso124,ISO 124]]] _Standard 124_
      * [[[iso123,1]]] _Standard 123_
    INPUT
    #{BLANK_HDR}
<sections><clause id="_" inline-header="false" obligation="normative">
  <title>Clause</title>
  <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
<eref type="inline" bibitemid="iso124" citeas="ISO 124"/></p>
</clause>
</sections><bibliography><references id="_" obligation="informative">
  <title>Bibliography</title>
  <bibitem id="iso124" type="standard">
  <title format="text/plain">Standard 124</title>
  <docidentifier>ISO 124</docidentifier>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>ISO</name>
    </organization>
  </contributor>
</bibitem>
  <bibitem id="iso123">
  <formattedref format="application/x-isodoc+xml">
    <em>Standard 123</em>
  </formattedref>
  <docidentifier type="metanorma">[2]</docidentifier>
</bibitem>
</references></bibliography>
       </ietf-standard>
OUTPUT
        end

                it "renumbers numeric references in Bibliography subclauses sequentially" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      <<iso123>>
      <<iso124>>
      <<iso125>>
      <<iso126>>

      [bibliography]
      == Bibliography

      [bibliography]
      === Clause 1
      * [[[iso124,ISO 124]]] _Standard 124_
      * [[[iso123,1]]] _Standard 123_

      [bibliography]
      === {blank}
      * [[[iso125,ISO 125]]] _Standard 124_
      * [[[iso126,1]]] _Standard 123_

    INPUT
    #{BLANK_HDR}
    <sections><clause id="_" inline-header="false" obligation="normative">
         <title>Clause</title>
         <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
       <eref type="inline" bibitemid="iso124" citeas="ISO 124"/>
       <eref type="inline" bibitemid="iso125" citeas="ISO 125"/>
       <eref type="inline" bibitemid="iso126" citeas="[4]"/></p>
       </clause>
       </sections><bibliography><clause id="_" obligation="informative"><title>Bibliography</title><references id="_" obligation="informative">
         <title>Clause 1</title>
         <bibitem id="iso124" type="standard">
         <title format="text/plain">Standard 124</title>
         <docidentifier>ISO 124</docidentifier>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
         <bibitem id="iso123">
         <formattedref format="application/x-isodoc+xml">
           <em>Standard 123</em>
         </formattedref>
         <docidentifier type="metanorma">[2]</docidentifier>
       </bibitem>
       </references>
       <references id="_" obligation="informative">
         
         <bibitem id="iso125" type="standard">
         <title format="text/plain">Standard 124</title>
         <docidentifier>ISO 125</docidentifier>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
         <bibitem id="iso126">
         <formattedref format="application/x-isodoc+xml">
           <em>Standard 123</em>
         </formattedref>
         <docidentifier type="metanorma">[4]</docidentifier>
       </bibitem>
       </references></clause></bibliography>
       </ietf-standard>
OUTPUT
        end

  it "converts boldface BCP to bcp markup if not no-rfc-bold-bcp14" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
    = Document title
    Author
    :docfile: test.adoc
    :nodoc:
    :novalid:
    :no-isobib:
    
    I *MUST NOT* do this.
    INPUT
        #{BLANK_HDR}
      <sections>
    <p id='_'>
      I
      <bcp14>MUST NOT</bcp14>
       do this.
    </p>
  </sections>
</ietf-standard>
    OUTPUT
    end

    it "does not convert boldface BCP to bcp markup if no-rfc-bold-bcp14" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :ietf, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
    = Document title
    Author
    :docfile: test.adoc
    :nodoc:
    :novalid:
    :no-isobib:
    :no-rfc-bold-bcp14:

    I *MUST NOT* do this.
    INPUT
    #{BLANK_HDR}
      <sections>
    <p id='_'>
      I
      <strong>MUST NOT</strong>
       do this.
    </p>
  </sections>
</ietf-standard>
    OUTPUT
    end

    it "imposes anchor loaded with RFC references" do
      expect(xmlpp(strip_guid(Asciidoctor::Ietf::Converter.new(nil, nil).rfc_anchor_cleanup(Nokogiri::XML(<<~INPUT)).to_xml))).to be_equivalent_to xmlpp(<<~"OUTPUT")
    <ietf-standard>
    <sections>
    <clause>
    <p><eref bibitemid="B"/></p>
    <termsource><origin bibitemid="A"/></termsource>
    </clause>
    </sections>
    <bibliography>
    <references>
    <bibitem id="B">
    <docidentifier type='rfc-anchor'>A</docidentifier>
    </bibitem>
    <bibitem id="A">
    <docidentifier type='rfc-anchor'>B</docidentifier>
    </bibitem>
    </references>
    </bibliography>
    </ietf-standard>
    INPUT
 <ietf-standard>
         <sections>
           <clause>
             <p>
               <eref bibitemid='A'/>
             </p>
             <termsource>
               <origin bibitemid='B'/>
             </termsource>
           </clause>
         </sections>
         <bibliography>
           <references>
             <bibitem id='A'>
               <docidentifier type='rfc-anchor'>A</docidentifier>
             </bibitem>
             <bibitem id='B'>
               <docidentifier type='rfc-anchor'>B</docidentifier>
             </bibitem>
           </references>
         </bibliography>
       </ietf-standard>
    OUTPUT
    end

end
