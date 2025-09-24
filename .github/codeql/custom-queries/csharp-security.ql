/**
 * @name C# Coding Guidelines - Missing Input Sanitization
 * @description User input should be sanitized before use
 * @kind problem
 * @id csharp/missing-input-sanitization
 * @severity error
 * @tags security
 * @precision high
 */

import csharp

from StringLiteral str, MethodCall call
where
  str.getValue().matches("%Echo: %") and
  call.getAnArgument() = str and
  not exists(MethodCall sanitize | 
    sanitize.getMethod().hasName(["Sanitize", "SanitizeMessage", "EscapeHtml"]) and
    sanitize.getAnArgument() = str
  )
select str, "Missing input sanitization. User input should be sanitized to prevent XSS attacks."
