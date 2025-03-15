from typing import Dict, List, Set, Tuple
import random
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict, Counter
import os
import urllib.parse
from sqlalchemy import create_engine
from sqlalchemy import text

# Set the local folder (the folder where this script resides)
fun = os.path.dirname(os.path.abspath(__file__))


class ScoutScheduler:
    """
    A scheduler for assigning scouts to monitor players/teams across a season.
    Uses a sliding window approach to optimize scout assignments across multiple matches.
    """

    def __init__(
        self,
        scout_names: List[str],
        lead_scout_names: List[str],
        total_matches: int,
        unavailability: Dict[str, List[int]],
        breaks: List[int],
        teams_to_scout: List[str] = None,
        target_consecutive_matches: int = 10,
        target_rest_matches: int = 10
    ):
        """
        Initialize the scout scheduler with required parameters.

        Args:
            scout_names: List of available scouts
            total_matches: Total number of matches in the season
            unavailability: Dictionary mapping scout names to match numbers they cannot attend
            breaks: List of matches after which there are scheduled breaks
            teams_to_scout: List of teams/players requiring scouting (default: R1, R2, R3, B1, B2, B3)
            target_consecutive_matches: Target number of consecutive matches for a scout
            target_rest_matches: Target number of rest matches between scouting periods
        """
        self.scout_names = scout_names
        self.total_matches = total_matches
        self.unavailability = unavailability
        self.lead_scout_names = lead_scout_names
        self.breaks = breaks
        self.teams_to_scout = teams_to_scout or ["R1", "R2", "R3", "B1", "B2", "B3"]
        self.target_consecutive_matches = target_consecutive_matches
        self.target_rest_matches = target_rest_matches

        # Initialize schedule as a nested dictionary
        self.schedule = {match: {team: None for team in self.teams_to_scout}
                         for match in range(1, total_matches + 1)}

        # Track assignments for each scout
        self.scout_assignments = {name: [] for name in scout_names}

        # Current consecutive matches worked
        self.active_streaks = {name: 0 for name in scout_names}
        # Whether scout needs rest
        self.rest_needed = {name: False for name in scout_names}
        self.last_worked = {name: -100 for name in scout_names}

        # Track team familiarity (which teams each scout has worked with)
        self.team_familiarity = {name: set() for name in scout_names}

        # Segment bounds (determined by scheduled breaks)
        self.segments = self._determine_segments()

        # Assignments per match - track how many teams each scout is monitoring each match
        self.match_assignments = {match: {name: 0 for name in scout_names} for match in range(1, total_matches + 1)}

    def _determine_segments(self) -> List[Tuple[int, int]]:
        """
        Determine the schedule segments based on scheduled breaks.

        Returns:
            List of tuples (start_match, end_match) for each segment
        """
        segments = []
        start_match = 1

        for break_match in self.breaks:
            segments.append((start_match, break_match))
            start_match = break_match + 1

        # Add the final segment
        segments.append((start_match, self.total_matches))

        return segments

    def is_available(self, scout: str, match: int) -> bool:
        """
        Check if a scout is available for a given match.

        Args:
            scout: The name of the scout
            match: The match number to check

        Returns:
            True if the scout is available, False otherwise
        """
        return match not in self.unavailability.get(scout, [])

    def should_rest(self, scout: str) -> bool:
        """Determine if scout needs mandatory rest"""
        return self.rest_needed[scout]

    def get_available_scouts(self, match: int) -> List[str]:
        """Override to enforce mandatory rest periods"""
        return [s for s in self.scout_names if self.is_available(s, match) and not self.rest_needed[s]]

    def select_scout_for_team(self, match: int, team: str, available_scouts: List[str]) -> str:
        """Enhanced selection with continuity incentives"""
        # Filter out scouts needing rest
        eligible = [s for s in available_scouts if not self.rest_needed[s]]
        # Get previous assignment for this team
        prev_assigned = self.schedule.get(match-1, {}).get(team)
        # Calculate scores
        scores = []
        for scout in eligible:
            # Base score components
            current_load = self.match_assignments[match][scout]
            total_assignments = len(self.scout_assignments[scout])
            familiarity = 1 if team in self.team_familiarity[scout] else 0
            # Continuity bonus (2x weight if worked previous match for this team)
            continuity = 2 if scout == prev_assigned else 0
            # Score components (lower is better)
            score = (current_load, -continuity, total_assignments, -familiarity)
            scores.append((score, scout))
        print(f"Selected {scout} for {team} (Match {match})")
        print(f"  Active streak: {self.active_streaks[scout]}")
        print(f"  Rest needed: {self.rest_needed[scout]}")
        print(f"  Last worked: {self.last_worked[scout]}")
        # Select scout with best score
        return min(scores)[1]

    def update_tracking_for_match(self, match: int) -> None:
        """Enhanced tracking with true consecutive streak detection"""
        for scout in self.scout_names:
            worked = any(self.schedule[match][team] == scout for team in self.teams_to_scout)
            if worked:
                if self.last_worked[scout] == match - 1:
                    self.active_streaks[scout] += 1
                else:
                    self.active_streaks[scout] = 1
                self.last_worked[scout] = match
                if self.active_streaks[scout] >= self.target_consecutive_matches:
                    self.rest_needed[scout] = True
            else:
                if self.is_available(scout, match):
                    if self.rest_needed[scout]:
                        rest_days = match - self.last_worked[scout]
                        if rest_days >= self.target_rest_matches:
                            self.rest_needed[scout] = False
                            self.active_streaks[scout] = 0
        print(f"Match {match} - Rest status:")
        for scout in self.scout_names:
            status = "RESTING" if self.rest_needed[scout] else "AVAILABLE"
            print(f"  {scout}: {status} | Streak: {self.active_streaks[scout]} | Last: {self.last_worked[scout]}")

    def reset_after_break(self) -> None:
        """Reset consecutive matches worked after a scheduled break."""
        self.rest_needed = {name: False for name in self.scout_names}

    def generate_schedule(self) -> None:
        """Generate the complete schedule using a sliding window approach."""
        for segment_start, segment_end in self.segments:
            for match in range(segment_start, segment_end + 1):
                available_scouts = self.get_available_scouts(match)
                if len(available_scouts) < len(self.teams_to_scout):
                    raise ValueError(f"Not enough scouts available for match {match}")
                for team in self.teams_to_scout:
                    if self.schedule[match][team] is not None:
                        continue
                    selected_scout = self.select_scout_for_team(match, team, available_scouts)
                    self.schedule[match][team] = selected_scout
                    self.scout_assignments[selected_scout].append((match, team))
                    self.match_assignments[match][selected_scout] += 1
                    self.team_familiarity[selected_scout].add(team)
                    if self.match_assignments[match][selected_scout] >= 1:
                        available_scouts = [s for s in available_scouts if s != selected_scout]
                self.update_tracking_for_match(match)
            if segment_end in self.breaks:
                self.reset_after_break()

    def optimize_schedule(self, iterations: int = 100) -> None:
        """
        Optimize the schedule by swapping assignments to improve team familiarity.

        Args:
            iterations: Number of optimization iterations
        """
        for _ in range(iterations):
            match = random.randint(1, self.total_matches)
            team1, team2 = random.sample(self.teams_to_scout, 2)
            scout1 = self.schedule[match][team1]
            scout2 = self.schedule[match][team2]
            if not scout1 or not scout2:
                continue
            if not self.is_available(scout1, match) or not self.is_available(scout2, match):
                continue
            current_score = ((1 if team1 in self.team_familiarity[scout1] else 0) +
                             (1 if team2 in self.team_familiarity[scout2] else 0))
            new_score = ((1 if team2 in self.team_familiarity[scout1] else 0) +
                         (1 if team1 in self.team_familiarity[scout2] else 0))
            if new_score > current_score:
                self.schedule[match][team1] = scout2
                self.schedule[match][team2] = scout1
                self.scout_assignments[scout1] = [(m, t if t != team1 else team2) for m, t in self.scout_assignments[scout1]]
                self.scout_assignments[scout2] = [(m, t if t != team2 else team1) for m, t in self.scout_assignments[scout2]]

    def to_dataframe(self) -> pd.DataFrame:
        """
        Convert schedule to a pandas DataFrame with lead scout assignments.
        
        Lead scouts are organized in pairs and rotated every 10 matches.
        Each pair consists of one scout from leadscoutone and one from leadscouttwo.
        
        Returns:
            DataFrame representation of the schedule with lead scout columns
        """
        data = []
        num_pairs = len(self.lead_scout_names) // 2
        leadscoutone = []
        leadscouttwo = []
        for i in range(0, len(self.lead_scout_names), 2):
            leadscoutone.append(self.lead_scout_names[i])
            leadscouttwo.append(self.lead_scout_names[i + 1])
        for match in range(1, self.total_matches + 1):
            row = {'Match': match}
            for team in self.teams_to_scout:
                row[team] = self.schedule[match][team]
            pair_index = ((match - 1) // 10) % num_pairs
            row['Lead1'] = leadscoutone[pair_index]
            row['Lead2'] = leadscouttwo[pair_index]
            data.append(row)
        return pd.DataFrame(data)

    def visualize_schedule(self, filename: str = fun + "scout_schedule.png") -> None:
        """
        Visualize the schedule as a colorful heatmap with scout names in the shaded boxes.

        Args:
            filename: Output file name for the visualization
        """
        df = self.to_dataframe()
        unique_scouts = list(set(self.scout_names))
        scout_to_index = {name: i for i, name in enumerate(unique_scouts)}
        numerical_data = np.zeros((self.total_matches, len(self.teams_to_scout)))
        for i in range(self.total_matches):
            for j, team in enumerate(self.teams_to_scout):
                scout = df.iloc[i][team]
                numerical_data[i, j] = scout_to_index.get(scout, -1)
        fig, ax = plt.subplots(figsize=(12, 20))
        cmap = plt.cm.get_cmap('tab20', len(unique_scouts))
        im = ax.imshow(numerical_data, cmap=cmap, aspect='auto')
        for break_match in self.breaks:
            ax.axhline(y=break_match - 0.5, color='red', linestyle='-', linewidth=2, alpha=0.7)
            ax.text(-0.5, break_match, f"Break", color='red', fontsize=10, ha='right', va='center')
        ax.set_xticks(np.arange(len(self.teams_to_scout)))
        ax.set_xticklabels(self.teams_to_scout)
        ax.set_yticks(np.arange(self.total_matches))
        ax.set_yticklabels(np.arange(1, self.total_matches + 1))
        ax.set_title("Scout Assignment Schedule")
        handles = [plt.Rectangle((0, 0), 1, 1, color=cmap(scout_to_index[name])) for name in unique_scouts]
        plt.legend(handles, unique_scouts, loc='upper left', bbox_to_anchor=(1, 1))
        ax.set_xticks(np.arange(-.5, len(self.teams_to_scout), 1), minor=True)
        ax.set_yticks(np.arange(-.5, self.total_matches, 1), minor=True)
        ax.grid(which='minor', color='black', linestyle='-', linewidth=0.5, alpha=0.2)
        for i in range(self.total_matches):
            for j, team in enumerate(self.teams_to_scout):
                scout = df.iloc[i][team]
                if scout:
                    ax.text(j, i, scout, ha='center', va='center', fontsize=8,
                            color='black' if numerical_data[i, j] != -1 else 'white')
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        plt.close()

    def analyze_schedule(self) -> Dict:
        """
        Analyze the generated schedule for various metrics.

        Returns:
            Dictionary of schedule analysis metrics
        """
        df = self.to_dataframe()
        assignment_counts = {}
        for scout in self.scout_names:
            count = 0
            for match in range(1, self.total_matches + 1):
                for team in self.teams_to_scout:
                    if df.loc[df['Match'] == match, team].values[0] == scout:
                        count += 1
            assignment_counts[scout] = count
        work_streaks = {}
        for scout in self.scout_names:
            streaks = []
            current_streak = 0
            for match in range(1, self.total_matches + 1):
                is_working = False
                for team in self.teams_to_scout:
                    if df.loc[df['Match'] == match, team].values[0] == scout:
                        is_working = True
                        break
                if is_working:
                    current_streak += 1
                elif current_streak > 0:
                    streaks.append(current_streak)
                    current_streak = 0
            if current_streak > 0:
                streaks.append(current_streak)
            work_streaks[scout] = streaks
        team_assignments = {}
        for scout in self.scout_names:
            team_counts = {team: 0 for team in self.teams_to_scout}
            for match in range(1, self.total_matches + 1):
                for team in self.teams_to_scout:
                    if df.loc[df['Match'] == match, team].values[0] == scout:
                        team_counts[team] += 1
            team_assignments[scout] = team_counts
        return {
            'assignment_counts': assignment_counts,
            'work_streaks': work_streaks,
            'team_assignments': team_assignments
        }

    def check_insufficient_rest(self, min_rest_period: int = None) -> Dict[str, List[Tuple[int, int, int]]]:
        """
        Check for scouts who have been reassigned without sufficient rest between assignments.

        This checks two conditions:
        1. If a scout has worked target_consecutive_matches in a row, they need rest
        2. If a scout is replaced for a team, they need rest before scouting again

        Args:
            min_rest_period: Minimum required matches between assignments (defaults to self.target_rest_matches)

        Returns:
            Dictionary mapping scout names to list of tuples (first_match, next_match, actual_rest_period, reason)
            for instances where scouts didn't get enough rest
        """
        if min_rest_period is None:
            min_rest_period = self.target_rest_matches
        insufficient_rest = defaultdict(list)
        last_worked_match = {name: 0 for name in self.scout_names}
        last_team_assignment = {name: {team: 0 for team in self.teams_to_scout} for name in self.scout_names}
        consecutive_worked = {name: 0 for name in self.scout_names}
        needs_rest = {name: False for name in self.scout_names}
        rest_started = {name: 0 for name in self.scout_names}
        for match in range(1, self.total_matches + 1):
            working_scouts = set()
            team_assignments = {}
            for team in self.teams_to_scout:
                scout = self.schedule[match][team]
                if scout:
                    working_scouts.add(scout)
                    team_assignments[team] = scout
                    for other_scout in self.scout_names:
                        if other_scout != scout and last_team_assignment[other_scout][team] == match - 1:
                            if not needs_rest[other_scout]:
                                needs_rest[other_scout] = True
                                rest_started[other_scout] = match
            for scout in working_scouts:
                if needs_rest[scout]:
                    rest_period = match - rest_started[scout]
                    if rest_period < min_rest_period:
                        is_break_between = any(rest_started[scout] <= b < match for b in self.breaks)
                        if not is_break_between:
                            reason = "Replaced on a team" if consecutive_worked[scout] < self.target_consecutive_matches else "Exceeded consecutive matches"
                            insufficient_rest[scout].append((rest_started[scout] - 1, match, rest_period, reason))
                    needs_rest[scout] = False
                if last_worked_match[scout] == match - 1:
                    consecutive_worked[scout] += 1
                else:
                    consecutive_worked[scout] = 1
                if consecutive_worked[scout] >= self.target_consecutive_matches:
                    needs_rest[scout] = True
                    rest_started[scout] = match + 1
                last_worked_match[scout] = match
                for team in self.teams_to_scout:
                    if team_assignments.get(team) == scout:
                        last_team_assignment[scout][team] = match
            for scout in set(self.scout_names) - working_scouts:
                consecutive_worked[scout] = 0
                if needs_rest[scout] and match - rest_started[scout] >= min_rest_period:
                    needs_rest[scout] = False
        return insufficient_rest

    def print_insufficient_rest_report(self, min_rest_period: int = None) -> None:
        """
        Print a detailed report about scouts who didn't receive sufficient rest between assignments.

        Args:
            min_rest_period: Minimum required matches between assignments (defaults to self.target_rest_matches)
        """
        if min_rest_period is None:
            min_rest_period = self.target_rest_matches
        insufficient_rest = self.check_insufficient_rest(min_rest_period)
        print(f"\nScout Insufficient Rest Report (Minimum rest: {min_rest_period} matches):")
        print("-" * 100)
        if not insufficient_rest:
            print("All scouts received adequate rest periods between assignments.")
            return
        print(f"{'Scout':<15} {'Last Match':<15} {'Next Match':<15} {'Rest Period':<15} {'Expected':<15} {'Reason':<25}")
        print("-" * 100)
        total_violations = 0
        for scout, violations in sorted(insufficient_rest.items(), key=lambda x: len(x[1]), reverse=True):
            for last_match, next_match, rest_period, reason in violations:
                print(f"{scout:<15} {last_match:<15} {next_match:<15} {rest_period:<15} {min_rest_period:<15} {reason:<25}")
                total_violations += 1
            if violations:
                print("-" * 100)
        print(f"\nTotal insufficient rest violations: {total_violations}")
        print(f"Scouts affected: {len(insufficient_rest)}/{len(self.scout_names)}")
        if total_violations > 0:
            violation_counts = Counter([v[2] for scout_list in insufficient_rest.values() for v in scout_list])
            most_common = violation_counts.most_common(3)
            print("\nMost common insufficient rest periods:")
            for rest_period, count in most_common:
                print(f"  {rest_period} matches: {count} occurrences ({count/total_violations*100:.1f}%)")
            reason_counts = Counter([v[3] for scout_list in insufficient_rest.values() for v in scout_list])
            print("\nViolations by reason:")
            for reason, count in reason_counts.items():
                print(f"  {reason}: {count} occurrences ({count/total_violations*100:.1f}%)")


def run_scout_scheduling():
    """Main function to run the scout assignment algorithm."""
    scout_names = ['Emma',
                   'Demir',
                   'Felicia',
                   'Hunter',
                   'Jake',
                   'Zidaan',
                   'Vikram',
                   'Asher',
                   'Daniel',
                   'Morgan',
                   'Chase',
                   'Thomas',
                   'Gabrielle',
                   'Matthew Ren',
                   'Alex Gavin',
                   'Michael',
                   'Isabel',
                   'Claudia',
                   'Sean',
                   'Niko',
                   ]
    total_matches = 74
    lead_scout_names = ['CJ','Mattin','Max','Andrew']
    unavailability = {
        
    }
    breaks = [22, 55]
    scheduler = ScoutScheduler(
        scout_names=scout_names,
        lead_scout_names=lead_scout_names,
        total_matches=total_matches,
        unavailability=unavailability,
        breaks=breaks,
        target_consecutive_matches=10,
        target_rest_matches=10
    )
    scheduler.generate_schedule()
    scheduler.optimize_schedule(iterations=500)
    scheduler.visualize_schedule(filename=fun + "scout_schedule.png")
    schedule_df = scheduler.to_dataframe()
    analysis = scheduler.analyze_schedule()
    print("Scout Assignment Schedule Generated!")
    print(f"Total matches: {total_matches}")
    print(f"Total scouts: {len(scout_names)}")
    print(f"Teams scouted: {scheduler.teams_to_scout}")
    return schedule_df


if __name__ == "__main__":
    schedule = run_scout_scheduling()
    schedule.to_csv(fun + "scout_schedule.csv", index=False)
    print("\nFull schedule saved to " + fun + "scout_schedule.csv")
    print("Visualization saved to " + fun + "scout_schedule.png")
    
    # Save the schedule to MSSQL Server
    # Set up connection parameters
    username = "1148Robotics"
    password = "1148Robotics"
    server = "MT-server\\SQLEXPRESS"
    database = "1148-Scouting"
    params = urllib.parse.quote_plus(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )
    engine = create_engine("mssql+pyodbc:///?odbc_connect=%s" % params)
    
    # Rename DataFrame columns to match the target schema:
    # 'Match' -> 'match_number', 'Lead1' -> 'blue_lead', 'Lead2' -> 'red_lead'
    df_to_save = schedule.rename(columns={
        "Match": "match_number",
        "Lead1": "blue_lead",
        "Lead2": "red_lead"
    })
    
    # Save to the MSSQL table called 'Assignment'
    with engine.begin() as connection:
        connection.execute(text("TRUNCATE TABLE Assignment"))
    df_to_save.to_sql("Assignment", engine, if_exists="replace", index=False)
    print("Schedule data saved to the Assignment table on MSSQL Server.")