require_relative "./test_ontology_common"
require "logger"

class TestClassModel < LinkedData::TestOntologyCommon

  def setup
  end

  def test_terms_custom_props
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load
    os_classes = os.classes
    os_classes.each do |c|
      assert(!c.prefLabel.nil?, "Class #{c.resource_id.value} does not have a label")
    end
    os.ontology.load
    os.ontology.delete
    os.delete
  end

  def test_class_where_id
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?
    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    classes = LinkedData::Models::Class.where( :submission => os, :resource_id => class_id )
    assert_instance_of(Array, classes)
    assert(classes.length == 1)
    assert_instance_of(LinkedData::Models::Class, classes[0])
    cls = classes[0]
    assert_equal 'class 5 pref label', cls.prefLabel.value
    assert_equal 0, cls.synonymLabel.length
    assert_equal 1, cls.definitions.length

    os.ontology.load
    os.ontology.delete
    os.delete
  end

  def test_class_parents
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    classes = LinkedData::Models::Class.where( :submission => os, :resource_id => class_id )
    assert(classes.length == 1)
    cls = classes[0]
    assert(!cls.loaded_parents?)
    assert_raise LinkedData::Models::ClassAttributeNotLoaded do
      cls.parents
    end
    parents = cls.load_parents
    assert(cls.loaded_parents?)
    assert_equal(parents, cls.parents)
    assert_equal(1, cls.parents.length)
    parent_id = "http://bioportal.bioontology.org/ontologies/msotes#class2"
    assert_equal(parent_id,cls.parents[0].resource_id.value)

    #they should have the same submission
    assert_equal(cls.parents[0].submission, os)

    #transitive
    cls.load_parents transitive=true
    ancestors = cls.parents
    ancestors.map! { |a| a.resource_id.value }
    data_ancestors = ["http://bioportal.bioontology.org/ontologies/msotes#class1",
 "http://bioportal.bioontology.org/ontologies/msotes#class2"]
    assert ancestors.sort == data_ancestors.sort

    os.ontology.load
    os.ontology.delete
    os.delete
  end

  def test_class_children
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class1"
    classes = LinkedData::Models::Class.where( :submission => os, :resource_id => class_id )
    assert(classes.length == 1)
    cls = classes[0]
    assert(!cls.loaded_children?)
    assert_raise LinkedData::Models::ClassAttributeNotLoaded do
      cls.children
    end
    children = cls.load_children
    assert(cls.loaded_children?)
    assert_equal(children, cls.children)
    assert_equal(1, cls.children.length)
    children_id = "http://bioportal.bioontology.org/ontologies/msotes#class2"
    assert_equal(children_id,cls.children[0].resource_id.value)

    #they should have the same submission
    assert_equal(cls.children[0].submission, os)


    #transitive
    cls.load_children transitive=true
    descendents = cls.children
    descendents.map! { |a| a.resource_id.value }
    data_descendents = ["http://bioportal.bioontology.org/ontologies/msotes#class_5",
 "http://bioportal.bioontology.org/ontologies/msotes#class2"]
    assert descendents.sort == data_descendents.sort

    os.ontology.load
    os.ontology.delete
    os.delete
  end

  def test_class_all_attributes
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class2"
    classes = LinkedData::Models::Class.where( :submission => os, :resource_id => class_id )
    assert(classes.length == 1)
    cls = classes[0]


    cls.load_attributes
    assert (cls.attributes["http://www.w3.org/2002/07/owl#versionInfo"][0].value == "some version info")


    os.ontology.load
    os.ontology.delete
    os.delete
  end

  def test_load_labels_separate
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class2"
    classes = LinkedData::Models::Class.where( :submission => os, :resource_id => class_id,
                                              :labels => false)
    assert(classes.length == 1)
    cls = classes[0]

    assert_raise LinkedData::Models::ClassAttributeNotLoaded do
      cls.prefLabel
    end
    assert_raise LinkedData::Models::ClassAttributeNotLoaded do
      cls.synonymLabel
    end
    assert_raise LinkedData::Models::ClassAttributeNotLoaded do
      cls.definitions
    end
    cls.load_labels
    assert(cls.prefLabel.kind_of? SparqlRd::Resultset::Literal)
    assert_instance_of Array, cls.synonymLabel
    assert(cls.synonymLabel[0].kind_of? SparqlRd::Resultset::Literal)
    assert_instance_of Array, cls.definitions
    assert(cls.definitions[0].kind_of? SparqlRd::Resultset::Literal)

    os.ontology.load
    os.ontology.delete
    os.delete
  end


end
