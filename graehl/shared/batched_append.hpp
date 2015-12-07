#ifndef GRAEHL__SHARED__batched_append_hpp
#define GRAEHL__SHARED__batched_append_hpp

#include <algorithm> //swap
#include <cstddef>

template <class SRange,class Vector>
void batched_append(Vector &v,SRange const& s) {
  std::size_t news=v.size()+s.size();
  v.reserve(news);
  v.insert(v.end(),s.begin(),s.end());
}

template <class SRange,class Vector>
void batched_append_swap(Vector &v,SRange & s) {
  using namespace std; // to find the right swap
  size_t i=v.size();
  size_t news=i+s.size();
  v.resize(news);
  typename SRange::iterator si=s.begin();
  for (;i<news;++i,++si)
    swap(v[i],*si);
}

#endif
