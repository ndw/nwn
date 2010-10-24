<p:declare-step version='1.0' name="main"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:p="http://www.w3.org/ns/xproc">
<p:input port="source"/>
<p:output port="result"/>

<p:try>
  <p:group>
    <p:validate-with-relax-ng>
      <p:input port="schema">
        <p:document href="../schema/essay.rng"/>
      </p:input>
    </p:validate-with-relax-ng>
    <p:validate-with-schematron>
      <p:input port="schema">
        <p:document href="../schema/docbook.sch"/>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
    </p:validate-with-schematron>
    <p:wrap-sequence wrapper="c:success">
      <p:input port="source" select="/c:errors"/>
    </p:wrap-sequence>
  </p:group>
  <p:catch name="catch">
    <p:identity>
      <p:input port="source">
        <p:pipe step="catch" port="error"/>
      </p:input>
    </p:identity>
  </p:catch>
</p:try>


</p:declare-step>
