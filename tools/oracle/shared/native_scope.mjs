// Keep differential evidence only where the selected native Date contract agrees.
// Native-only parsing/display behavior is covered by dedicated V conformance tests.
function commonISO(value) {
 if(typeof value!=='string')return false;
 const match=/^(\d{4})-(\d{2})-(\d{2})(?:[Tt ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,9}))?)?(?:[Zz]|[+-]\d{2}:\d{2}))?$/.exec(value);
 if(!match)return false;
 const [,y,m,d,h='0',minute='0',second='0']=match;
 const year=+y, month=+m, day=+d;
 const lengths=[31,year%4===0&&(year%100!==0||year%400===0)?29:28,31,30,31,30,31,31,30,31,30,31];
 return month>=1&&month<=12&&day>=1&&day<=lengths[month-1]&&+h<=23&&+minute<=59&&+second<=59;
}

export function filterNativeDateRows(corpus, rows) {
 return rows.filter(row=>{
  if(corpus==='boxed_date'&&row.family==='conversion') {
   return !(row.action==='toString'&&row.stamp!==null) && !(row.action==='toDate'&&row.placement==='array');
  }
  if(corpus==='maybe_conversion') {
   if(row.state!=='value')return true;
   if(row.action==='toString'&&row.kind==='date')return false;
   if(row.action==='toDate'&&row.kind==='text')return false;
  }
  if(corpus==='native_hook_audit'&&row.family==='primitive'&&row.action==='toDate'&&row.kind==='text')return false;
  if(row.action==='toDate') {
   if(Array.isArray(row.input))return false;
   if(typeof row.input==='string'&&row.success&&!commonISO(row.input))return false;
  }
  return true;
 });
}
