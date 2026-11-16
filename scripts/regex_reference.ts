// ECMAScript reference cases consumed by the native V regression suite.
const patterns = [
  ['^.$',''], ['^.$','u'], ['^..$',''], ['a','g'], ['a','y'], ['a','gy'],
  ['^\\p{L}+$','u'], ['^[[a-z]--[aeiou]]+$','v'], ['(?<=a)b',''],
  ['^(?<letter>[a-z])\\k<letter>$','i'], ['^a$','m'], ['.','s'],
  ['^\\w+$','iu'], ['^\\d+$','u'], ['[/\\n]',''], ['', 'g'],
  ['^.$','v'], ['[\\uD800-\\uDBFF]',''], ['a.*b','s'], ['^\\s$','u'],
];
const inputs=['a','aa','ab','ba','😀','é','Клиника','bcdf','aeiou','ſ','K','１２','\na\n','\u2028','/',''];
const cases=patterns.map(([pattern,flags])=>{
 const re=new RegExp(pattern,flags);
 return {pattern,flags,expected:re.toString(),inputs,results:inputs.map(input=>({matched:re.test(input)}))};
});
console.log(JSON.stringify(cases,null,2));
