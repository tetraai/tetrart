//
// Copyright (c) 2023, Tetra Intelligence Systems, Inc. All rights reserved.
//

#pragma once

/**
 * Run some code when leaving a scope.
 */
class OnScopeExit
{
  public:
    OnScopeExit(const OnScopeExit&) = delete;
    OnScopeExit(OnScopeExit&&) = delete;
    OnScopeExit& operator=(const OnScopeExit&) = delete;
    OnScopeExit& operator=(OnScopeExit&&) = delete;

    OnScopeExit(std::function<void()> f)
        : m_f(std::move(f)){};

    ~OnScopeExit()
    {
        try
        {
            m_f();
        }
        catch (...)
        {
            // Not worth crashing over
        }
    }

  private:
    std::function<void()> m_f;
};
