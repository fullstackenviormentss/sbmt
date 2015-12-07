#ifndef GRAEHL_SHARED__PATH_TRAITS_HPP
#define GRAEHL_SHARED__PATH_TRAITS_HPP

/// traits for (n-)best paths of graphs/hypergraphs. note: your cost_type may be a<b means a better than b (mostly to simplify) or you can override better_cost(). better is used to order the heap and test convergence. updates is the same for viterbi but may always return true if you want to sum all paths? unsure.

#include <boost/graph/graph_traits.hpp>
#include <boost/iterator/counting_iterator.hpp>
#include <graehl/shared/epsilon.hpp>

namespace graehl {

// for additive costs (lower = better)
template <class Float=float>
struct cost_path_traits
{
  typedef Float cost_type;
  static const bool viterbi = true; // means updates() sometimes returns false. a<b with combine(a,a)=a would suffice
  static inline cost_type unreachable() { return std::numeric_limits<cost_type>::infinity(); }
  static inline cost_type start() { return 0; }
  static inline cost_type extend(cost_type a,cost_type b) { return a+b; }
  static inline cost_type retract(cost_type a,cost_type b) { return a-b; }
  static inline cost_type combine(cost_type a,cost_type b) { return std::min(a,b); }
  static inline bool better(cost_type a,cost_type const&b)
  {
    return a<b;
  }
  static inline bool update(cost_type candidate,cost_type &best) {
    if (candidate<best) {
      best=candidate; return true;
    }
    return false;
  }
  static inline bool updates(cost_type candidate,cost_type best) { return candidate<best; }
  static inline cost_type repeat(cost_type a,float n) { return a*n; }
  static inline bool includes(cost_type candidate,cost_type best) { // update(you can assert this after update)
    return !(candidate<best);
  }
  static inline bool includes(cost_type candidate,cost_type best,float delta_relative) {
    assert(delta_relative>=0);
    float delta=delta_relative;
    if (candidate<0) //relative delta; unweighted (relative to 1) if 0 candidate
      delta*=-candidate;
    if (candidate>0)
      delta*=candidate;
    return !(candidate+delta<best);
  }
  static inline bool close_enough(cost_type a,cost_type b,float delta_relative=FLOAT_EPSILON) { return includes(a,b,delta_relative)&&includes(b,a,delta_relative); } // also for debugging
  // may be different from includes in the same way that better is different from update:
  static inline bool converged(cost_type improver,cost_type incumbent
                               ,cost_type epsilon)
  {
    return includes(improver,incumbent,epsilon); // may be different for other cost types (because float may not = cost_Type)
  }
};

template <class G>
struct path_traits : cost_path_traits<float> {
};

/*
template <class G>
static inline bool converged(typename path_traits<G>::cost_type const& improver,typename path_traits<G>::cost_type const& incumbent
  ,typename path_traits<G>::cost_type const& epsilon)
{
  typedef path_traits<G> PT;
  return PT::better(incumbent,PT::combine(improver,epsilon));
}
*/

// for graphs which have edges with sources (plural) and not source - ordered multihypergraphs
template <class G>
struct edge_traits {
  typedef typename path_traits<G>::cost_type cost_type;
  typedef boost::graph_traits<G> GT;
  typedef unsigned tail_descriptor;
  typedef boost::counting_iterator<tail_descriptor> tail_iterator;
  typedef unsigned tails_size_type; // must always be unsigned. for now
};

/*
  free fns (ADL):

  none. statics in path_traits, instead
*/


template <class G>
struct updates_cost {
  typedef path_traits<G> PT;
  typedef typename PT::cost_type cost_type;
  typedef bool result_type;
  inline bool operator()(cost_type const& a,cost_type const& b) const {
    return PT::updates(a,b);
  }
};

template <class G>
struct better_cost {
  typedef path_traits<G> PT;
  typedef typename PT::cost_type cost_type;
  typedef bool result_type;
  inline bool operator()(cost_type const& a,cost_type const& b) const {
    return PT::better(a,b);
  }
};

}//ns

#endif
