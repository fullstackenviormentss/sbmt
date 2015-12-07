#ifndef SBMT_CHART_FORCE_SENTENCE_CELL_HPP
#define SBMT_CHART_FORCE_SENTENCE_CELL_HPP

#include <sbmt/span.hpp>
#include <sbmt/edge/edge.hpp>
#include <sbmt/range.hpp>
#include <sbmt/search/concrete_edge_factory.hpp>

#include <boost/multi_index_container.hpp>
#include <boost/multi_index/hashed_index.hpp>


namespace sbmt {

namespace detail {

/// ordered cells return their edge equivalents from highest score to
/// lowest score
template <class EdgeT>
class force_sentence_cell {
public:
    typedef edge_equivalence<EdgeT> edge_equiv_type;
    typedef EdgeT edge_type;
private:
    struct hash_left_espan {
        typedef span_index_t result_type;
        result_type operator() (edge_equiv_type const& eq1) const
        {
            return eq1.representative().info().info().espan().left();
        }
    };
    struct hash_key_by_edge {
        typedef edge_type result_type;
        edge_type const& operator()(edge_equiv_type eq) const
        {
            return eq.representative();
        }
    };
    
    typedef boost::multi_index_container <
                edge_equiv_type
              , boost::multi_index::indexed_by<
                    boost::multi_index::hashed_non_unique<
                        hash_left_espan
                    >
                  , boost::multi_index::hashed_unique<
                        hash_key_by_edge
                    >
                >
            > edge_container_t;
public:
    typedef typename edge_container_t::iterator iterator;
            
    typedef itr_pair_range<iterator> range;

    std::pair<iterator,bool> find(edge_type const& e) const;
    
    range         edges() const;
    range items() const 
    { return edges(); }
    
    range         edges(span_index_t left) const;
    indexed_token root() const;
    span_t        span() const;
    score_t       best_score() const;
    
    void insert_edge( edge_equivalence_pool<EdgeT>& epool
                    , edge_type const& e);
    void insert_edge( edge_equiv_type const& e);
    
    /// we do not want to allow empty cells:  that would force checking
    force_sentence_cell(edge_equivalence_pool<EdgeT>& epool, edge_type const& e);
    force_sentence_cell(edge_equiv_type const& eq);

    std::size_t size() const 
    { return edge_container.size(); }
    
private:
    struct edge_inserter {
        edge_inserter(edge_type const* e)
        : e(e) {}
        edge_type const*  e;
        void operator()(edge_equiv_type& eq) { eq.insert_edge(*e); }
    };
    
    struct edge_merger {
        edge_merger(edge_equiv_type const* eq )
        : eq(eq) {}
        edge_equiv_type const*  eq;
        void operator()(edge_equiv_type& c) { c.merge(*eq); }
    };
    
    edge_merger merging_edges(edge_equiv_type const& eq)
    { return edge_merger(&eq); }

    edge_inserter
    inserting_edge( edge_type const& e )
    {
        return edge_inserter(&e);
    }
    edge_container_t edge_container;
    
    score_t best_scr;
};

} // namespaace sbmt::detail

////////////////////////////////////////////////////////////////////////////////
/// 
/// passing this structure into the charts template parameter allows the chart
/// to use force_sentence_cell as its cell_type, which allows edges to be sorted by
/// score in an cell
///
////////////////////////////////////////////////////////////////////////////////
struct force_sentence_chart_edges_policy
{
    enum { ordered = true }; // changed from false so force_decode w/ beams works
    template<class EdgeT> struct cell_type {
        typedef detail::force_sentence_cell<EdgeT> type;
    };
};

////////////////////////////////////////////////////////////////////////////////

} // namespace sbmt

#include <sbmt/chart/impl/force_sentence_cell.ipp>

#endif // SBMT_ORDERED_CELL_HPP
