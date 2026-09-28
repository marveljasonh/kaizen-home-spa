import { createClient } from "@/lib/supabase/server";

export async function getContent(): Promise<Record<string, string>> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("website_content")
    .select("key, value");

  return (
    data?.reduce(
      (acc, row) => {
        acc[row.key] = row.value;
        return acc;
      },
      {} as Record<string, string>
    ) ?? {}
  );
}
