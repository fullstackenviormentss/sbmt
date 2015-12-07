/*#include <sbmt/edge/edge.hpp>
#include <sbmt/edge/edge_equivalence.hpp>
#include <sbmt/edge/null_info.hpp>
#include <sbmt/edge/joined_info.hpp>
#include <sbmt/grammar/grammar_in_memory.hpp>
#include <sbmt/sentence.hpp>

#include <boost/test/auto_unit_test.hpp>
#include <boost/multi_index_container.hpp>
#include <boost/multi_index/hashed_index.hpp>
#include <boost/multi_index/mem_fun.hpp>

#include <sstream>

#include "grammar_examples.hpp"
#include "test_util.hpp"

using namespace boost;
using namespace boost::multi_index;
using namespace sbmt;
using namespace std;

    typedef edge<null_info>                       tm_edge;
    typedef grammar_in_mem                        gram_t;
    typedef concrete_edge_factory<tm_edge,gram_t> tm_edge_factory;
    typedef tm_edge_factory::edge_equiv_type      tm_edge_equiv;
    typedef edge_equivalence_pool<tm_edge>        tm_equiv_pool;



struct inserting_edge {
    inserting_edge(tm_edge const& e):e(e){}
    void operator()(tm_edge_equiv& eq) { eq.insert_edge(e); }
    tm_edge const& e;  
};

struct tm_edge_extract
{
    typedef tm_edge result_type;
    tm_edge const& operator()(tm_edge_equiv const& ptr) const
    { return ptr.representative(); }
};

struct tm_span_extract
{
    typedef span_t result_type;
    span_t operator()(tm_edge_equiv const& ptr) const
    { return ptr.span(); }
};

/// makeshift chart (those reading the code may have come to realize i am
/// in love with boost::multi_index_container):
typedef multi_index_container< 
            tm_edge_equiv
          , indexed_by< 
                hashed_unique<tm_edge_extract>
              , hashed_non_unique<tm_span_extract>
            >           
        > tm_makeshift_chart;

typedef tm_makeshift_chart::nth_index<1>::type tm_span_view;
typedef tm_makeshift_chart::iterator           tm_edge_equiv_iterator;
typedef tm_span_view::iterator                 tm_span_iterator;
typedef itr_pair_range<tm_span_iterator>       tm_span_range;
        
void insert_edge( tm_makeshift_chart& chart
                , tm_equiv_pool& epool
                , tm_edge const& e )
{
    tm_makeshift_chart::iterator pos = chart.find(e);
    if (pos == chart.end()) {
        tm_edge_equiv eq = epool.create(e);
        chart.insert(eq);
    } else {
        chart.modify(pos,inserting_edge(e));
    }
}

tm_span_range span_range(tm_makeshift_chart const& chart, span_t s)
{
    std::pair<tm_span_iterator,tm_span_iterator> p =
        chart.get<1>().equal_range(s);
        
    return tm_span_range(p.first,p.second);
}

void apply_binary_rules( tm_makeshift_chart& chart
                       , gram_t const& gram
                       , tm_edge_factory& ef
                       , tm_equiv_pool& epool
                       , gram_t::rule_type r
                       , tm_edge_equiv const& e_left
                       , tm_span_range const&  range_right)
{
    tm_span_iterator itr_right = range_right.begin();
    tm_span_iterator end_right = range_right.end();
    
    //BOOST_CHECK(e_left.empty() == false);
    
    for (; itr_right != end_right; ++itr_right) {
        if (itr_right->representative().root() == gram.rule_rhs(r,1)) {
        	span_t combo_span = combine( e_left.representative().span()
                                       , itr_right->representative().span());
                                       
            BOOST_CHECKPOINT("before create binary edge");
            tm_edge e = ef.create_edge(gram,r,e_left,*itr_right);
            BOOST_CHECKPOINT("after create binary edge");
            
            BOOST_CHECK(
                e.span() == combo_span
             );
            insert_edge(chart,epool,e);
        }
    }
}

void apply_binary_rules( tm_makeshift_chart& chart
                       , gram_t const& gram
                       , tm_edge_factory& ef
                       , tm_equiv_pool& epool
                       , gram_t::rule_range& r
                       , tm_edge_equiv const& e_left
                       , tm_span_range const& range_right )
{
    gram_t::rule_iterator rule_itr = r.begin();
    gram_t::rule_iterator rule_end = r.end();
    
    for (; rule_itr != rule_end; ++rule_itr) {
        apply_binary_rules(chart,gram,ef,epool,*rule_itr,e_left,range_right);
    }
}

void apply_binary_rules( tm_makeshift_chart& chart
                       , gram_t const& gram
                       , tm_edge_factory& ef
                       , tm_equiv_pool& epool
                       , tm_span_range const& range_left
                       , tm_span_range const& range_right )
{
    tm_span_iterator itr_left = range_left.begin();
    tm_span_iterator end_left = range_left.end();
    
    for (; itr_left != end_left; ++itr_left) {
        gram_t::rule_range r = 
            gram.binary_rules(itr_left->representative().root());
        apply_binary_rules(chart,gram,ef,epool,r,*itr_left,range_right);
    }    
}

void apply_unary_rules( tm_makeshift_chart& chart
                      , gram_t const& gram
                      , tm_edge_factory& ef
                      , tm_equiv_pool& epool
                      , gram_t::rule_range range
                      , tm_edge_equiv const& eq )
{
    gram_t::rule_iterator rule_itr = range.begin();
    gram_t::rule_iterator rule_end = range.end();
    
    for (; rule_itr != rule_end; ++rule_itr) {
        BOOST_CHECKPOINT("before create unary edge");
        tm_edge e = ef.create_edge(gram, *rule_itr, eq);
        BOOST_CHECKPOINT("after create unary edge");
        BOOST_CHECK(e.span() == eq.representative().span());
        insert_edge(chart,epool,e);
    }
}


void apply_unary_rules( tm_makeshift_chart& chart
                      , gram_t const& gram
                      , tm_edge_factory& ef
                      , tm_equiv_pool& epool
                      , tm_span_range const& range )
{
    /// for the time being, we are handling unary rules incorrectly, by only allowing
    /// one iteration
    tm_span_iterator itr = range.begin();
    tm_span_iterator end = range.end();
    
    for (; itr != end; ++itr) {
        //BOOST_CHECK(itr->empty() == false);
        gram_t::rule_range r = 
            gram.unary_rules(itr->representative().root());
        apply_unary_rules(chart,gram,ef,epool,r,*itr);
    }
}



void lame_cyk_fill_chart( tm_makeshift_chart& chart
                        , gram_t const& gram
                        , tm_edge_factory& ef
                        , tm_equiv_pool& epool
                        , span_t max_span )
{
    span_t s(0,1);
    for (; s.right() <= max_span.right(); s = shift_right(s)) {
        apply_unary_rules(chart,gram,ef,epool,span_range(chart,s));
    }
    
    for (unsigned size = 1; size <= length(max_span); ++size) {
        span_t s(0,size);
        for (; s.right() <= max_span.right(); s = shift_right(s)) {
            partitions_generator pg(s);
            partitions_generator::iterator pitr = pg.begin();
            partitions_generator::iterator pend = pg.end();
            
            for (; pitr != pend; ++pitr) {
                tm_span_range range_left = span_range(chart,pitr->first);
                tm_span_range range_right= span_range(chart,pitr->second);
                apply_binary_rules(chart,gram,ef,epool,range_left,range_right);
            }
            apply_unary_rules(chart,gram,ef,epool,span_range(chart,s));
        }
    }
}


void print_span_range( tm_makeshift_chart& chart
                     , gram_t& gram
                     , tm_span_range range
                     , span_t s )
{
    cout << s;
    tm_span_iterator itr = range.begin();
    for (; itr != range.end(); ++itr) {
        cout << gram.label(itr->representative().root());
        cout << ",";
    }
}


void print_acceptance_chart( tm_makeshift_chart& chart
                           , gram_t& gram
                           , span_t max_span )
{
    for (unsigned size = 1; size <= length(max_span); ++size) {
        for (span_t s(0,size); s.right() <= max_span.right(); s = shift_right(s)) {
            tm_span_range range = span_range(chart,s);
            print_span_range(chart,gram,range,s);
            cout << "   ";
        }
        cout << endl;
    }
}

/// just a simple test to ensure the contents of a grammar source file are 
/// all represented in our grammar_in_mem
///
/// \todo: if we implement another grammar type (likely), then templatize this
/// code to test all grammar implementations
BOOST_AUTO_TEST_CASE(test_grammar_contents)
{
    BOOST_CHECKPOINT("begin test grammar contents");
    gram_t gram;
    init_grammar_marcu_1(gram);
    typedef gram_t gram_traits;
    
    stringstream strstr;    
    
    //// print the rules, or rather, insert them into a collection:
    gram_traits::rule_range all = gram.all_rules();
    multiset<string> rule_set;
    gram_traits::token_factory_type& tf = gram.dict();
    gram_traits::rule_iterator all_itr = all.begin();
    for(; all_itr != all.end(); ++all_itr)
    {
        string r = tf.label(gram.rule_lhs(*all_itr)) 
                 + " -> " 
                 + tf.label(gram.rule_rhs(*all_itr,0));
        if (gram.rule_rhs_size(*all_itr) == 2) 
            r = r +" "+ tf.label(gram.rule_rhs(*all_itr,1));
        rule_set.insert(r);
    }
    
    multiset<string> rule_set_expected = simplified_grammar_strings_marcu_1();
    
    BOOST_CHECK_EQUAL_COLLECTIONS( rule_set_expected.begin()
                                 , rule_set_expected.end()
                                 , rule_set.begin()
                                 , rule_set.end() );
                                 
    gram_traits::rule_range2 range2;
    gram_traits::rule_iterator2 itr2;
    
    /// make sure i can find the rule NNP -> "FRANCE" with score 0.8
    /// by looking up unary_rules("FRANCE")
    indexed_token FRANCE = tf.foreign_word("FRANCE");
    gram_traits::rule_range range = gram.unary_rules(FRANCE);
    
    gram_traits::rule_iterator itr = range.begin();
    BOOST_CHECK(itr != range.end());
    indexed_token NNP = tf.tag("NNP");
    BOOST_CHECK(gram.rule_lhs(*itr) == NNP);
    BOOST_CHECK(gram.is_complete_rule(*itr));
    LOGNUMBER_CHECK_CLOSE(score_t(0.8), gram.rule_score(*itr),score_t(0.00001));
    
    BOOST_CHECK(gram.rule_lm_string(*itr) == 
                indexed_lm_string(string("\"France\""),tf));
                
    //cout << print(gram.rule_lm_string(*itr),tf) << endl;
    ++itr;
    BOOST_CHECK(itr == range.end());
    
    /// make sure i can find the rule VBP -> "INCLUDE" with score 0.3
    /// by looking up unary_rules("INCLUDE")
    indexed_token INCLUDE = tf.foreign_word("INCLUDE");
    range = gram.unary_rules(INCLUDE);
    itr = range.begin();
    BOOST_CHECK(itr != range.end());
    indexed_token VBP = tf.tag("VBP");
    BOOST_CHECK(gram.rule_lhs(*itr) == VBP);
    BOOST_CHECK(gram.is_complete_rule(*itr));
    LOGNUMBER_CHECK_CLOSE(score_t(0.3), gram.rule_score(*itr),score_t(0.00001));
    ++itr;
    BOOST_CHECK(itr == range.end());
    
    /// make sure i can find the rule S -> V[NP___VP_] . with score 0.2
    /// by looking up binary_rules("V[NP___VP_]")
    indexed_token V_NP_VP = tf.virtual_tag("V[NP___VP_]");
    indexed_token period  = tf.tag(".");
    indexed_token S       = tf.tag("S");
    range = gram.binary_rules(V_NP_VP);
    itr   = range.begin();
    BOOST_CHECK(itr != range.end());
    BOOST_CHECK(gram.rule_rhs_size(*itr) == 2);
    BOOST_CHECK(gram.rule_rhs(*itr,1) == period);    
    BOOST_CHECK(gram.rule_lhs(*itr) == S);
    BOOST_CHECK(score_t(0.2) == gram.rule_score(*itr));
    ++itr;
    BOOST_CHECK(itr == range.end());
    
    range2 = gram.binary_rules(V_NP_VP,period);
    itr2   = range2.begin();
    BOOST_CHECK(itr2 != range2.end());
    BOOST_CHECK(gram.rule_rhs_size(*itr2) == 2);
    BOOST_CHECK(gram.rule_rhs(*itr2,1) == period);    
    BOOST_CHECK(gram.rule_lhs(*itr2) == S);
    BOOST_CHECK(score_t(0.2) == gram.rule_score(*itr2));
    ++itr2;
    BOOST_CHECK(itr2 == range2.end());
    
    BOOST_CHECKPOINT("test VP -> \"COMINGFROM\" NP");
    
    /// make sure i can find two complete binary rules by looking up
    /// binary_rules("COMINGFROM"), and both match
    /// VP -> "COMINGFROM" NP (though they have distinct syntax rules)
    std::size_t id1, id2;
    indexed_token COMINGFROM = tf.foreign_word("COMINGFROM");
    indexed_token NP  = tf.tag("NP");
    indexed_token VP  = tf.tag("VP");
    range = gram.binary_rules(COMINGFROM);
    itr   = range.begin();
    BOOST_CHECK(itr != range.end());
    BOOST_CHECK(gram.rule_rhs_size(*itr) == 2);
    BOOST_CHECK(gram.rule_rhs(*itr,1) == NP);   
    BOOST_CHECK(gram.rule_lhs(*itr) == VP);
    BOOST_CHECKPOINT("test VP -> \"COMINGFROM\" access syntax rule");
    id1 = gram.get_syntax(*itr).id();
    indexed_lm_string const& lmstr = gram.rule_lm_string(*itr);
    BOOST_CHECK(lmstr.size() == 3);
    BOOST_CHECK(lmstr[0].is_token() == true);
    BOOST_CHECK(lmstr[1].is_token() == true);
    BOOST_CHECK(lmstr[1] == tf.native_word("from"));
    BOOST_CHECK(lmstr[2].is_token() == false);
    BOOST_CHECK(lmstr[2] == 0);
    ++itr;
    BOOST_CHECKPOINT("test VP -> \"COMINGFROM\" NP pass first rule");
    BOOST_CHECK(itr != range.end());
    BOOST_CHECK(gram.rule_rhs_size(*itr) == 2);
    BOOST_CHECK(gram.rule_rhs(*itr,1) == NP);   
    BOOST_CHECK(gram.rule_lhs(*itr) == VP);
    id2 = gram.get_syntax(*itr).id();
    BOOST_CHECK(lmstr.size() == 3);
    BOOST_CHECK(lmstr[0].is_token() == true);
    BOOST_CHECK(lmstr[1].is_token() == true);
    BOOST_CHECK(lmstr[1] == tf.native_word("from"));
    BOOST_CHECK(lmstr[2].is_token() == false);
    BOOST_CHECK(lmstr[2] == 0);
    ++itr;
    BOOST_CHECKPOINT("test VP -> \"COMINGFROM\" NP pass second rule");
    BOOST_CHECK(itr == range.end());
    
    BOOST_CHECK(id1 != id2);
    BOOST_CHECKPOINT("end test grammar contents");
}

BOOST_AUTO_TEST_CASE(test_edge_null_info)
{   
    gram_t gram;
    init_grammar_marcu_1(gram);
    
    tm_edge_factory tmf;
    tm_equiv_pool tmpool;
   
    string fss = "THESE 7PEOPLE INCLUDE COMINGFROM FRANCE AND RUSSIA p-DE ASTRO- -NAUTS .";
    fat_sentence s = foreign_sentence(fss);
    
    fat_sentence::iterator itr = s.begin();
    fat_sentence::iterator end = s.end();
    
    list<tm_edge> tm_edge_list;
    tm_makeshift_chart chart;
   
    int i=0;
    for(; itr != end; ++itr,++i) {
        tm_edge e = tmf.create_edge(gram,itr->label(),span_t(i,i+1));
        tm_edge_equiv eq = tmpool.create(e);
        BOOST_CHECK(is_lexical(*itr));
        BOOST_CHECK(is_lexical(eq.representative().root()));
        chart.insert(eq);
    }
     
    lame_cyk_fill_chart(chart, gram, tmf, tmpool, span_t(0,i));
    //print_acceptance_chart(chart,gram,span_t(0,i));
    tm_span_range srange = span_range(chart,span_t(0,i));
    tm_span_iterator sitr = srange.begin();
    BOOST_CHECK(sitr != srange.end());
}

*/
