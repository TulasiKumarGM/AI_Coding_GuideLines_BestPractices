/**
 * @name C# Coding Guidelines - Missing ConfigureAwait
 * @description Async methods in library code should use ConfigureAwait(false)
 * @kind problem
 * @id csharp/missing-configureawait
 * @severity warning
 * @tags performance
 * @precision medium
 */

import csharp

from MethodCall call
where
  call.getMethod().hasName(["ReadAllAsync", "WriteAsync", "GetByIdAsync", "CreateAsync"]) and
  not call.getAnArgument().(MethodCall).getMethod().hasName("ConfigureAwait") and
  call.getEnclosingCallable().isAsync()
select call, "Missing ConfigureAwait(false) in async method. Add .ConfigureAwait(false) to prevent deadlocks."
