/**
 * @name C# Coding Guidelines - Missing Input Validation
 * @description Methods should validate input parameters for null values
 * @kind problem
 * @id csharp/missing-input-validation
 * @severity error
 * @tags security
 * @precision high
 */

import csharp
import semmle.code.csharp.dataflow.DataFlow

from Method m, Parameter p
where
  m.hasName(["HandleIncomingMessage", "Echo", "Add", "Subtract", "Multiply", "Divide"]) and
  p = m.getAParameter() and
  not exists(IfStmt ifs | 
    ifs.getCondition().(NullLiteral).getParent() = p.getAnAccess() and
    ifs.getThen().(ThrowStmt).getAnExpression().(ObjectCreation).getType().hasQualifiedName("System", "ArgumentNullException")
  )
select m, "Missing input validation for parameter " + p.getName() + ". Add null checks and throw ArgumentNullException."
