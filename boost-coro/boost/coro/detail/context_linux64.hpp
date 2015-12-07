//  Copyright (c) 2007 Robert Perricone
//  Copyright (c) 2007-2009 Hartmut Kaiser
//
//  Distributed under the Boost Software License, Version 1.0.
//  (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_COROUTINE_CONTEXT_LINUX_HPP_20071126
#define BOOST_COROUTINE_CONTEXT_LINUX_HPP_20071126

#if defined(__GNUC__) && defined(__x86_64__) && !defined(BOOST_COROUTINE_NO_ASM)
#include <cstdlib>
#include <cstddef>
#include <boost/coro/detail/posix_utility.hpp>
#include <boost/coro/detail/swap_context.hpp>
#include <boost/assert.hpp>
/* 
 * Defining BOOST_COROUTINE_NO_SEPARATE_CALL_SITES will disable separate 
 * invoke, yield and yield_to swap_context functions. Separate calls sites
 * increase performance by 25% at least on P4 for invoke+yield back loops
 * at the cost of a slightly higher instruction cache use and is thus enabled by
 * default.
 */
//#define BOOST_COROUTINE_NO_SEPARATE_CALL_SITES

extern "C" void swapcontext_stack (void***, void**) throw();
extern "C" void swapcontext_stack2 (void***, void**) throw();
extern "C" void swapcontext_stack3 (void***, void**) throw();

///////////////////////////////////////////////////////////////////////////////
namespace boost { namespace coros { 

  // some platforms need special preparation of the main thread
  struct prepare_main_thread
  {
    prepare_main_thread() {}
    ~prepare_main_thread() {}
  };

  namespace detail { namespace oslinux64 
		     {
    template<typename T>
    void trampoline(T* fun);

    template<typename T>
    inline void
    trampoline(T* fun) 
    { 
      (*fun)();
      std::abort();
    }

		       class ia64_gcc_context_impl;

    class ia64_gcc_context_impl_base 
    {
    public:
      ia64_gcc_context_impl_base() {}

      void prefetch() const 
      {
        __builtin_prefetch (m_sp, 1, 3);
        __builtin_prefetch (m_sp, 0, 3);
        __builtin_prefetch ((void**)m_sp+64/8, 1, 3);
        __builtin_prefetch ((void**)m_sp+64/8, 0, 3);
        __builtin_prefetch ((void**)m_sp+32/8, 1, 3);
        __builtin_prefetch ((void**)m_sp+32/8, 0, 3);
        __builtin_prefetch ((void**)m_sp-32/8, 1, 3);
        __builtin_prefetch ((void**)m_sp-32/8, 0, 3);
        __builtin_prefetch ((void**)m_sp-64/8, 1, 3);
        __builtin_prefetch ((void**)m_sp-64/8, 0, 3);
      }

      /**
       * Free function. Saves the current context in @p from
       * and restores the context in @p to.
       * @note This function is found by ADL.
       */     
      friend void swap_context(ia64_gcc_context_impl_base& from, 
			       ia64_gcc_context_impl const& to, default_hint);

#ifndef BOOST_COROUTINE_NO_SEPARATE_CALL_SITES
      friend void swap_context(ia64_gcc_context_impl& from, 
			       ia64_gcc_context_impl_base const& to, yield_hint);

      friend void swap_context(ia64_gcc_context_impl& from, 
			       ia64_gcc_context_impl_base const& to, yield_to_hint);
#endif

    protected:
      void ** m_sp;
    };

		       class ia64_gcc_context_impl : public ia64_gcc_context_impl_base
		       {
		       public:
			 enum { default_stack_size = 2*8192 };

			 typedef ia64_gcc_context_impl_base context_impl_base;

			 ia64_gcc_context_impl() 
			   : m_stack(0) 
			 {}

			 /**
			  * Create a context that on restore invokes Functor on
			  *  a new stack. The stack size can be optionally specified.
			  */
      template<typename Functor>
      ia64_gcc_context_impl(Functor& cb, std::ptrdiff_t stack_size = -1) 
        : m_stack_size(stack_size == -1 ? default_stack_size : stack_size),
          m_stack(posix::alloc_stack(m_stack_size)) 
			 {
			   BOOST_ASSERT(m_stack);
			   m_sp = ((void**)m_stack + (m_stack_size/sizeof(void*)));

			   *(void**)m_stack = (void*)~0;            // fill the last word with ones

			   typedef void fun(Functor*);
			   fun * funp = trampoline;

			   // we have to make sure that the stack pointer is aligned on a 16 Byte
			   // boundary when the code is entering the trampoline (the stack itself
			   // is already properly aligned)
			   *--m_sp = 0;       // additional alignment

			   *--m_sp = &cb;     // parm 0 of trampoline;
			   *--m_sp = 0;       // dummy return address for trampoline
			   *--m_sp = (void*) funp ;// return addr (here: start addr)  NOTE: the unsafe cast is safe on IA64
			   *--m_sp = 0;       // rbp
			   *--m_sp = 0;       // rbx
			   *--m_sp = 0;       // rsi
			   *--m_sp = 0;       // rdi
			   *--m_sp = 0;       // r12
			   *--m_sp = 0;       // r13
			   *--m_sp = 0;       // r14
			   *--m_sp = 0;       // r15
			 }
      
			 ~ia64_gcc_context_impl() 
			 {
			   if(m_stack)
			     posix::free_stack(m_stack, m_stack_size);
			 }

			 friend void swap_context(ia64_gcc_context_impl_base& from, 
						  ia64_gcc_context_impl const& to, default_hint);

#ifndef BOOST_COROUTINE_NO_SEPARATE_CALL_SITES
			 friend void swap_context(ia64_gcc_context_impl& from, 
						  ia64_gcc_context_impl_base const& to, yield_hint);

			 friend void swap_context(ia64_gcc_context_impl& from, 
						  ia64_gcc_context_impl_base const& to, yield_to_hint);
#endif

		       private:
			 std::ptrdiff_t m_stack_size;
			 void * m_stack;
		       };
    
		       typedef ia64_gcc_context_impl context_impl;

		       /**
			* Free function. Saves the current context in @p from
			* and restores the context in @p to.
			* @note This function is found by ADL.
			*/     
		       inline void swap_context(ia64_gcc_context_impl_base& from, 
						ia64_gcc_context_impl const& to, default_hint) 
		       {
			 //        BOOST_ASSERT(*(void**)to.m_stack == (void*)~0);
			 to.prefetch();
			 swapcontext_stack(&from.m_sp, to.m_sp);
		       }

#ifndef BOOST_COROUTINE_NO_SEPARATE_CALL_SITES
		       inline void swap_context(ia64_gcc_context_impl& from, 
						ia64_gcc_context_impl_base const& to, yield_hint) 
		       {
			 //        BOOST_ASSERT(*(void**)from.m_stack == (void*)~0);
			 to.prefetch();
			 swapcontext_stack2(&from.m_sp, to.m_sp);
		       }

		       inline void swap_context(ia64_gcc_context_impl& from, 
						ia64_gcc_context_impl_base const& to, yield_to_hint) 
		       {
			 //        BOOST_ASSERT(*(void**)from.m_stack == (void*)~0);
			 to.prefetch();
			 swapcontext_stack3(&from.m_sp, to.m_sp);
		       }
#endif

  }
  }}}

#elif defined(__linux)
/**
 * For all other linux systems use the standard posix implementation.
 */
#include <boost/coro/detail/context_posix.hpp>
namespace boost { namespace coros { namespace detail { 
  namespace oslinux64 
  {
    typedef posix::context_impl context_impl;
  } 
}}}
#else
#error This header can only be included when compiling for linux systems.
#endif

#endif

