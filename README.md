CakePHP Extension
=================

This is an experiment of porting some classes from CakePHP to a PHP extension
using [Zephir](http://zephir-lang.com).

**This is only an experiment. Do not use in production!**

This project do not replace CakePHP and it will never will. The goal of this
project is to improve Cake's performance in production.

Feel free to contribute. :smile:

Using
-----

Install Zephir, then you can compile the extension doing:
`zephir compile`

You can configure your php ini's to use the compile extension or run like that:
`php -d extension=ext/modules/cake.so -r 'var_dump(Cake\Utility\Hash::get(["that" => ["is" => "nice"]], "that.is"));'`
