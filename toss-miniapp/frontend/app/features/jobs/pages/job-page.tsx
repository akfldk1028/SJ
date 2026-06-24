import { Badge } from "~/common/components/ui/badge";
import type { Route } from "./+types/job-page";
import { DotIcon, LockIcon } from "lucide-react";
import { Button } from "~/common/components/ui/button";
import { getJobById } from "../queries";
import { DateTime } from "luxon";
import { makeSSRClient } from "~/supa-client";

export const meta: Route.MetaFunction = ({ data }) => {
  return [{ title: `${data.job.position} | wemake` }];
};

export const loader = async ({ request, params }: Route.LoaderArgs) => {
  const { client } = makeSSRClient(request);
  const job = await getJobById(client, { jobId: params.jobId });
  return { job };
};

export default function JobPage({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <div className="bg-gradient-to-tr from-primary/80 to-primary/10 h-60 w-full rounded-lg"></div>
      <div className="grid grid-cols-1  md:grid-cols-6 -mt-20 md:gap-20 items-start">
        <div className="md:col-span-4 space-y-10">
          <div>
            <div className="size-32 md:size-40 bg-white rounded-full overflow-hidden relative md:left-10 md:right-auto left-auto right-auto mx-auto md:mx-0">
              <img src={loaderData.job.company_logo} className="object-cover" />
            </div>
            <h1 className="text-4xl font-bold mt-5">
              {loaderData.job.position}
            </h1>
            <h4 className="text-lg text-muted-foreground">
              {loaderData.job.company_name}
            </h4>
          </div>
          <div className="flex gap-2 capitalize">
            <Badge variant={"secondary"}>{loaderData.job.job_type}</Badge>
            <Badge variant={"secondary"}>{loaderData.job.location}</Badge>
          </div>
          <div className="space-y-2.5">
            <h4 className="text-2xl font-bold">Overview</h4>
            <p className="text-lg">{loaderData.job.overview}</p>
          </div>
          <div className="space-y-2.5">
            <h4 className="text-2xl font-bold">Responsibilities</h4>
            <ul className="text-lg list-disc list-inside">
              {loaderData.job.responsibilities.split(",").map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
          <div className="space-y-2.5">
            <h4 className="text-2xl font-bold">Qualifications</h4>
            <ul className="text-lg list-disc list-inside">
              {loaderData.job.qualifications.split(",").map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
          <div className="space-y-2.5">
            <h4 className="text-2xl font-bold">Benefits</h4>
            <ul className="text-lg list-disc list-inside">
              {loaderData.job.benefits.split(",").map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
          <div className="space-y-2.5">
            <h4 className="text-2xl font-bold">Skills</h4>
            <ul className="text-lg list-disc list-inside">
              {loaderData.job.skills.split(",").map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
        </div>
        <div className="md:col-span-2 space-y-5 md:mt-32 sticky top-20 p-6 border rounded-lg">
          <div className="flex flex-col">
            <span className=" text-sm text-muted-foreground">Avg. Salary</span>
            <span className="text-2xl font-medium">
              {loaderData.job.salary_range}
            </span>
          </div>
          <div className="flex flex-col">
            <span className=" text-sm text-muted-foreground">Location</span>
            <span className="text-2xl font-medium capitalize">
              {loaderData.job.location}
            </span>
          </div>
          <div className="flex flex-col">
            <span className=" text-sm text-muted-foreground">Type</span>
            <span className="text-2xl font-medium capitalize">
              {loaderData.job.job_type}
            </span>
          </div>
          <div className="flex">
            <span className=" text-sm text-muted-foreground">
              Posted{" "}
              {DateTime.fromISO(loaderData.job.created_at, {
                zone: "utc",
              }).toRelative()}
            </span>
            <DotIcon className="size-4" />
            {/* <span className=" text-sm text-muted-foreground">395 views</span> */}
          </div>
          <Button className="w-full cursor-not-allowed hover:*">
            <LockIcon className="size-4" /> Applications Closed
          </Button>
        </div>
      </div>
    </div>
  );
}
