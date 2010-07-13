import org.jcoffeescript.*
jsc = new JCoffeeScriptCompiler()
println jsc.compile(new File(args[0]).text)

