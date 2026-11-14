import {createServerClient} from "@supabase/ssr";
import {cookies} from "next/headers";
export async function createSupabaseServerClient(){
 const jar=await cookies();
 return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,{
  cookies:{getAll(){return jar.getAll()},setAll(values: {name:string;value:string;options?:any}[]){try{values.forEach(({name,value,options})=>jar.set(name,value,options))}catch{ /* Server Component cookie writes are handled by middleware/routes */}}}
 });
}