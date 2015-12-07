// wraps Boost or regular random number generators
#ifndef GRAEHL_SHARED__RANDOM_HPP
#define GRAEHL_SHARED__RANDOM_HPP

#ifdef SOLARIS
//# include <sys/int_types.h>
//FIXME: needed for boost/random - report bug to boost.org? (actually no, had uint32_t, just bug in pass_through_engine.hpp trying to get uint32_t::base_type
#endif

#include <cmath> // also needed for boost/random :( (pow)
#include <algorithm> // min for boost/random
#include <boost/random.hpp>
#ifdef USE_NONDET_RANDOM
# ifndef __linux__
# undef USE_NONDET_RANDOM
# else
# include <boost/nondet_random.hpp>
# if defined (RANDOM_SINGLE_MAIN)
// should be included in boost libraries? this is a locally bugfixed version, but latest boost should work
# include "nondet_random.cpp"
# endif
#endif
#endif

#ifndef USE_STD_RAND
# define USE_STD_RAND 1
#endif

#if USE_STD_RAND
# include <cstdlib>
#endif

#include <boost/scoped_array.hpp>

#include <ctime>
#include <graehl/shared/os.hpp>

#ifdef GRAEHL_TEST
#include <graehl/shared/test.hpp>
#include <cctype>
#endif

namespace graehl {

typedef unsigned random_seed_type;

inline random_seed_type debugging_random_seed(random_seed_type n)
{
  return (n+1)*2654435769U;
}

inline random_seed_type default_random_seed()
{
// long pid=get_process_id();
# ifdef USE_NONDET_RANDOM
  return boost::random_device().operator()();
# else
  random_seed_type pid=(random_seed_type)get_process_id();
  return (random_seed_type)std::time(0) ^ pid ^ (pid << 17);
# endif
}

#ifndef USE_STD_RAND
//FIXME: maybe use faster integer type rng? then maybe faster random ints
typedef boost::lagged_fibonacci607 G_rgen;

typedef boost::uniform_01<G_rgen> G_rdist;
#if (!defined(GRAEHL__NO_RANDOM_MAIN) && defined(GRAEHL__SINGLE_MAIN)) || defined(GRAEHL__RANDOM_MAIN)
static G_rgen g_random_gen(default_random_seed());
G_rdist g_random01(g_random_gen);
#else
extern G_rdist g_random01;
#endif
#endif

inline void set_random_seed(random_seed_type value=default_random_seed())
{
#if USE_STD_RAND
  srand(value);
#else
  g_random01.base().seed(value);
#endif
}


//FIXME: use boost random? and can't necessarily port executable across platforms with different rand syscall :(
inline double random01() // returns uniform random number on [0..1)
{
# if USE_STD_RAND

  return ((double)std::rand()) * (1. /((double)RAND_MAX+1.));
# else
  return g_random01();
# endif
}

inline double random0n(double n) // random from [0..n)
{
  return n*random01();
}


inline double random_pos_fraction() // returns uniform random number on (0..1]
{
#ifdef USE_STD_RAND
  return ((double)std::rand()+1.) *
    (1. / ((double)RAND_MAX+1.));
#else
  return 1.-random01();
#endif
}

template <class V1,class V2>
inline V1 random_half_open(const V1 &v1, const V2 &v2)
{
  return v1+random01()*(v2-v1);
}

struct set_random_pos_fraction {
  template <class C>
  void operator()(C &c) {
    c=random_pos_fraction();
  }
};

template <class Int>
inline Int random_less_than(Int limit) {
  if (limit <= 1)
    return 0;
#if USE_STD_RAND
  assert(limit<=RAND_MAX);
// correct against bias (which is worse when limit is almost RAND_MAX)
  const Int randlimit=(RAND_MAX / limit)*limit;
  Int r;
  while ((r=std::rand()) >= randlimit) ;
  return r % limit;
#else
  return (Int)(random01()*limit);
#endif
}

inline bool random_bool()
{
  return random_less_than(2);
}

template <class Int>
inline Int random_up_to(Int limit) {
#if USE_STD_RAND
  if (limit==RAND_MAX) return (Int)std::rand();
#endif
  return random_less_than(limit+1);
}


#define GRAEHL_RANDOM__NLETTERS 26
// works for only if a-z A-Z and 0-9 are contiguous
inline char random_alpha() {
  unsigned r=random_less_than((unsigned)(GRAEHL_RANDOM__NLETTERS*2));
  return (r < GRAEHL_RANDOM__NLETTERS) ? 'a'+r : ('A'-GRAEHL_RANDOM__NLETTERS)+r;
}

inline char random_alphanum() {
  unsigned r=random_less_than((unsigned)(GRAEHL_RANDOM__NLETTERS*2+10));
  return r < GRAEHL_RANDOM__NLETTERS*2 ?
    ((r < GRAEHL_RANDOM__NLETTERS) ? 'a'+r : ('A'-GRAEHL_RANDOM__NLETTERS)+r)
    : ('0'-GRAEHL_RANDOM__NLETTERS*2)+r;
}
#undef GRAEHL_RANDOM__NLETTERS

inline std::string random_alpha_string(unsigned len) {
  boost::scoped_array<char> s(new char[len+1]);
  char *e=s.get()+len;
  *e='\0';
  while(s.get() < e--)
    *e=random_alpha();
  return s.get();
}

// P(*It) = double probability (unnormalized).
template <class It,class P>
It choose_p(It begin,It end,P const& p)
{
  if (begin==end) return end;
  double sum=0.;
  for (It i=begin;i!=end;++i)
    sum+=p(*i);
  double choice=sum*random01();
  for (It i=begin;;) {
    choice -= p(*i);
    It r=i;
    ++i;
    if (choice<0 || i==end) return r;
  }
  return begin; //unreachable
}

// P(*It) = double probability (unnormalized).
template <class Sum,class It,class P>
It choose_p_sum(It begin,It end,P const& p)
{
  if (begin==end) return end;
  Sum sum=0.;
  for (It i=begin;i!=end;++i)
    sum+=p(*i);
  double choice=random01();
  for (It i=begin;;) {
    choice -= p(*i)/sum;
    It r=i;
    ++i;
    if (choice<0 || i==end) return r;
  }
  return begin; //unreachable
}

// as above but already normalized
template <class It,class P>
It choose_p01(It begin,It end,P const& p)
{
  double sum=0.;
  double choice=random01();
  for (It i=begin;;) {
    sum+=p(*i);
    It r=i;
    ++i;
    if (sum>choice || i==end) return r;
  }
  return begin; //unreachable
}


template <class It>
void randomly_permute(It begin,It end)
{
  using std::swap;
  size_t N=end-begin;
  for (size_t i=0;i<N;++i) {
    swap(*(begin+i),*(begin+random_up_to(i)));
  }
}

template <class V>
void randomly_permute(V &vec)
{
  using std::swap;
  size_t N=vec.size();
  for (size_t i=0;i<N;++i) {
    swap(vec[i],vec[random_up_to(i)]);
  }
}


#ifdef GRAEHL_TEST
BOOST_AUTO_TEST_CASE( TEST_RANDOM )
{
  using namespace std;
  const int NREP=10000;
  for (int i=1;i<NREP;++i) {
    unsigned ran_lt_i=random_less_than(i);
    BOOST_CHECK(0 <= ran_lt_i && ran_lt_i < i);
    BOOST_CHECK(isalpha(random_alpha()));
    char r_alphanum=random_alphanum();
    BOOST_CHECK(isalpha(r_alphanum) || isdigit(r_alphanum));
  }
}
#endif
}

#endif
